**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-sol
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
OpenAI Codex v0.153.4
--------
workdir: /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-93733-mu26k550
model: gpt-5.6-sol
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 01a0b197-48af-70d2-879c-62117385d4cd
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Consult: vote on HiQS-Labs/XYZ-forge#681 — two edits to the relay-automation harness

You are one of two independent advisors. Read the files named below yourself (you are in a throwaway worktree of XYZ-forge at `development`), then give a **separate vote on A and on B**: `YES`, `NO`, or `YES-WITH-CHANGE` (state the change). A coordinator will reconcile both advisors' answers and break ties. Advisory only; write nothing.

## What happened (the case that motivates the issue)

The capped final-QA relay for issue #673 (`relay-system/2026-09-17/gh673-final-qa.md` on branch `feat/gh646-flightdeck-reader` — not in this worktree; the transcript is summarised here) ran three Reviewer/Producer rounds and escalated without approval, while carrying a design it had itself requested in Round 1 that makes the feature unusable on real data:

- Round 1 Reviewer `[Blocker]`: "Root errors discovered after rows are copied … *or a later invalid identity* … never reach those copied evidence dictionaries. Fix: carry finalized root completeness … conservatively withhold confirmation where configured evidence is unresolved." This conflated an unreadable *root* (we don't know what it holds) with one unqualifiable *row* (already neutralised by the helper: no events attach to it).
- The Producer implemented it literally. Round 2, the same Reviewer marked its own request `[Pass]`.
- Effect: one historical roadmap row with `issue_url NULL` (GH-135 — 1 of 202 rows in this repo's own `releases.db`) flags the whole ledger root incomplete, and every issue's status becomes "Unavailable".
- Every Reviewer turn opened with "no code, artifact, test or git command was executed." The defect was found only by an out-of-relay review that *measured* (counted the rows), then reconciled with the Producer in a two-lab discussion where falsify-by-fixture ran in both directions.

## The two proposed edits (prose in prompt/template text only; no shell logic)

**A. Let the Reviewer measure, read-only.**
File: `relay-automation/relay-turn-lib.sh`, the reviewer `role_note` string (around line 1042). Current text:
> "You are the REVIEWER this turn: do NOT edit, create, or run any artifact or source file — ONLY append your graded findings to the relay file. Any other edit will be reverted and fail the turn."

Proposed:
> "You are the REVIEWER this turn: do NOT edit or create any artifact or source file. You MAY run existing tests, fixtures, and read-only probes against the seeded artifact to measure a claim; write all output under `.relay-scratch/`. Any change to the tree outside the relay file is reverted and fails your turn."

Context to check yourself: the `.relay-scratch/` affordance and its exemption (`scratch_note`, ~line 1050); the `XYZ_TOOL_MODE=programmatic` note (~1052-1054); the containment enforcement `rtl_enforce` and how it computes the dirty set (does it see gitignored files such as `__pycache__`?); the existing prohibition on running the *full* gate in the same prompt (~1056) — which stays as written; `decisions/2026-06-15-unattended-agent-containment.md` if present; `relay-automation/README.md` rows for `relay-turn-lib.sh`.

**B. Reviewer-requested design changes must carry their own falsifier.**
File: `relay-automation/new-relay.sh`, the Reviewer bullet in the `▶ TAKE YOUR TURN` block (~lines 79-92). Proposed addition after the GH-173 citation sentence:
> "A finding that asks for a **design change** (not a fix to a defect you observed) MUST state its falsifier: the concrete input or fixture that would show the requested design is wrong. A design request without a falsifier is downgraded to `[Should — no falsifier]`; the Producer may Decline it on that basis alone, and a later `[Pass]` on it must cite the falsifier having been run."
Plus a one-line mirror in the Producer bullet's disposition list.

Context to check yourself: the existing GH-268 whole-file rule and GH-173 B3 citation rule in the same block (they guard *observations*, not *requests*); `ROUND_CAP` default (line 24) — round budgets are 3-4.

## Counter-arguments already on the table (engage with them; add your own)

1. A measuring reviewer can leave files (`__pycache__`, temp fixture dirs) that trip `rtl_enforce` and discard the turn — the reason the full-gate ban exists. Is scratch-only output plus gitignore exclusion actually sufficient, or does A need a mechanism (e.g. `PYTHONDONTWRITEBYTECODE`, a scratch-cwd), not just prose?
2. "Read-only execution" — is that a category the harness can *enforce*, or only *ask for*? If only ask for, does A widen the blast radius meaningfully given the worktree seed + Codex `-s read-only`?
3. B adds friction to every design-shaped finding and may push reviewers to phrase design requests as "defects". Is the observed/requested distinction crisp enough to be enforced by a reviewer, or by the harness's mechanical downgrade (as GH-173 does for uncited `[Pass]`)?
4. B may consume a round from a 3-4 round cap.
5. Alternative to both: leave the harness alone and rely on out-of-relay cross-lab review (which is what caught this). Is that cheaper and just as good?

## Answer format (strict)

```
VOTE A: YES | NO | YES-WITH-CHANGE
Reason (≤5 bullets, cite file:line you actually read):
Change (if YES-WITH-CHANGE):

VOTE B: YES | NO | YES-WITH-CHANGE
Reason (≤5 bullets, cite file:line):
Change (if YES-WITH-CHANGE):

One risk the other advisor will probably miss:
```

codex
I’m using the `consult` skill because this is explicitly a one-shot cross-model advisory review. I’ll apply only its advisor-side review discipline here—no further fan-out—and inspect the cited harness and policy files read-only.
exec
/bin/zsh -lc "sed -n '1,240p' /Users/noelsaw/.codex/skills/consult/SKILL.md" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-93733-mu26k550
 succeeded in 0ms:
---
name: consult
description: >-
  One-shot cross-model CONSULT — fan the same question out to Codex and agy in parallel (repo-isolated, advisory), then reconcile their answers into one. Use when the user wants a "second opinion", to "ask Codex and agy", a "panel" or "cross-model" check, or an independent gut-check on a decision/design/doc before committing — and does NOT need an iterative build/review loop. NOT a relay: a relay is an iterative 1:1 Producer↔Reviewer loop that converges an artifact; a consult is a parallel 1-shot 1:N second opinion, reconciled once. Depends on the codex + agy CLIs and the relay-automation shims; runs in any repo that ships them at the repo root OR in a vendored `.xyz/` install (the skill resolves either).
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
the XYZ-forge (or XYZ mini) checkout **and** in any repo that has a vendored `.xyz/` install: the
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
XYZ-forge/XYZ mini checkout, or (XYZ-forge only) vendor a `.xyz/` into the target repo first
(`relay-automation/xyz-vendor.sh <repo>`). (Do **not** go hunting the disk for `consult.sh`; the
anchor above always finds it.)

**Repository isolation (CWD-level, not a process sandbox).** Advisors run with their working directory set to a
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
  [--models codex,agy]                   # default pair; claude is also supported (Python runtime)
  [--out DIR]                            # parent dir (default relay-system/<today>/)
  [--label SLUG]                         # run-subdir + transcript stem (default "consult")
```

For native Claude, follow [subscription setup](https://github.com/HiQS-Labs/XYZ-forge/blob/development/relay-automation/README.md#claude-subscription-mode).
`--models claude` is a single advisory answer, not cross-model consensus. Claude uses read-only
built-in tools in native restricted mode; user/project/local settings are ignored in both
authentication modes, and outside-checkout reads are denied by the CLI. See the setup guide
for the CLI requirement and effort settings. Relay reviews separately retain protocol writes.

Each run gets its own `<label>-<HHMMSS>/` subdir, so two consults the same day never overwrite each
other. Behavior is covered by `test/consult.sh` in XYZ-forge's `validate.sh` (WIP preservation, no advisor leak,
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
- **Repo-isolated, not process-sandboxed.** Advisors run in a throwaway worktree, so an advisor that
  ignores the "advisory only" instruction edits the worktree, not your checkout. Be precise about the
  boundary: the worktree shares the repository's Git object store and the advisor CLI runs with the
  host's normal permissions (agy is launched with `--dangerously-skip-permissions`), so this protects
  your *working tree*, not the *host* or *Git state*.
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
  so any repo carrying a `.xyz/` (see `relay-automation/xyz-vendor.sh` in XYZ-forge) can run consult standalone.

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

exec
/bin/zsh -lc "sed -n '1,220p' ROUTER.md && sed -n '1,180p' GUIDING-PRINCIPLES.md" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-93733-mu26k550
 succeeded in 0ms:
# ROUTER.md

This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.

## Role split

- `ROUTER.md` = startup order and canonical entry points
- `GUIDING-PRINCIPLES.md` = XYZ Forge’s product purpose, scope and *why*, and the canonical North Star: durable, reversible, DRY — extend what exists rather than forking a parallel system
- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof
- `README.md` = human-facing repo/product overview
- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file
- `CHANGELOG.md` = the end-of-iteration running log (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
- `RELEASES DB` = the single runtime and release-planning ledger (`releases.db` via `releases.sql`; operated through `releases_app.py`); `RELEASES.md` is retired (GH-568)
- `HARNESS-MODELS-REGISTRY.md` = evaluated agent harnesses, supported model grades (A/B/C), and CLI flags
- `MACHINE-CONTRACTS.md` = the Jog ↔ Preflight ↔ Marathon machine-contract reference (`marathon-invocation@1`, `marathon-drive/result@1`) and their version/deprecation policy
- `PROJECT/**` docs = canonical execution detail for a specific effort
- `PROJECT/PDDA.md` = shared PDDA document contract maintained in Forge (incl. CHANGELOG); repo-specific adoption policy stays in this router
- `PROJECT/CONSTITUTION.md` = locally maintained PDDA-layer policy of record, with verified-success, reversibility and local-first safeguards adopted by XYZ; advisory-only LLM checking is PDDA-specific and does not replace XYZ relay approval
- `PROJECT/DO-NOT-BUILD.md` = locally maintained PDDA anti-scope; XYZ product scope remains in GUIDING-PRINCIPLES, not a blanket prohibition on coordination or execution
- `PROJECT/PDDA-MODE-GUIDE.md` = XYZ-maintained guidance for selecting PDDA’s enforcement mode
- `PROJECT/PDDA-SYNC-POLICY.md` = binding XYZ-owned review policy for PDDA distribution updates

## Startup sequence

1. Read `ROUTER.md` to understand the repo's operating order and canonical files. -> expect one clear next file, not a repo-wide scavenger hunt.
2. Read `AGENTS.md` before making recommendations or edits. -> expect explicit assumptions, a reversibility read on consequential changes, and verified claims only.
3. Run `python3 utils/py/releases_app.py roadmap list` to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)
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

## PDDA distribution

Forge is canonical for PDDA. `utils/pdda/pdda-install.sh` installs governance into targets;
`utils/pdda/pdda-sync.sh` updates registered targets from the shared manifest.
Read [PDDA migration](docs/PDDA-MIGRATION.md) before switching an existing distributor.
Targets own their startup documents; generic templates live under `utils/pdda/templates/`.

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
remote refs, development). Run the gate from a separate disposable full clone; `XYZ_ALLOW_WORKTREE_GATE=1` is the
announced override for disposable runs.

**Local push checks and hosted CI both apply.** This repository is public; the workflow covers
pushes and pull requests to `main` and `development`. Hosted macOS promotion evidence requires an
actual passing run for the exact commit; the Ubuntu canary remains advisory. Install the local
hook with `githooks/install.sh` for each clone — `.git/hooks/` does not travel with a clone. One
installation covers that clone’s branches and linked worktrees. Run mutation-heavy gates and
pushes that invoke them from a separate disposable full clone, as required by AGENTS.md.
Bypasses (`git push --no-verify`, `XYZ_SKIP_PREPUSH=1`) announce that the local gate was skipped.
**Draft-review publication is distinct from merge readiness (GH-487):** an operator-requested WIP
draft may use a bypass only with (a) current focused evidence for the changed area — e.g. the
mapped subsystem's suites run green — (b) the hook's skipped-gate disclosure echoed into the PR
description, and (c) merge readiness still outstanding. A bypassed push never authorises merge,
promotion, or teardown, and a published draft is never approval.

**Parallel became the default on 2026-08-14 (GH-544)** when the local gate was the only gate during
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
agent-chorus, standup, skills-army-hq); a push the classifier rates `tier=2` runs only those focused
suites at the boundary, `--tier 1` runs the docs gate, and everything else — unknown paths, unclaimed
test edits, kernel surfaces — runs the full suite. `--auto` classifies a local diff the same way.
Tiers 1 and 2 are pre-push speed and are labelled NOT promotion evidence; only `ci-local.sh`'s
sequential full run qualifies (GH-509).

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
utils/pdda/pdda.sh releases         # legacy releases check (skips when RELEASES.md is retired)
utils/pdda/pdda.sh releases-current # read-only roll-up: queries releases.db (GH-568)
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

**Subsystem 1 — releases** (GH-32 / GH-568): the release ledger. App-managed writes
only; `releases.db` and the `releases` CLI (`releases list`, `releases show`) are the sole source of truth (`RELEASES.md` is retired per GH-568).
**Subsystem 2 — the roadmap ledger** (GH-69 shadow → GH-238/GH-243 canonical → GH-269 retired ROADMAP.md → GH-567 retired ROADMAP-DASHBOARD.md): since the
`ROADMAP_SOURCE=releases` flip, `roadmap_items` IS the ledger — write rows with
`releases roadmap add` (or `hq park`), read with `roadmap list`.
The legacy markdown roadmap files (ROADMAP and ROADMAP-DASHBOARD) have been retired. `roadmap sync` exists for legacy-mode repos only and
no-ops here by design (it would delete `add`-parked rows). Pinned by `test/gh69-roadmap-shadow.sh`,
`test/gh238-hq-releases-mode.sh`, `test/gh269-roadmap-retired.sh`, and `test/gh567-roadmap-dashboard-retired.sh`.

## Routing hints

- If the task is about current priorities or active work, start with `releases roadmap list`, then follow the linked `PROJECT/**` doc.
- If the task changes the roadmap ledger, write through the CLI (`releases roadmap add` for intake; `hq park` routes there automatically).
- If the task touches `releases.db`, `releases.sql`, or a merge conflict on either, start in [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md); writes go through the CLI, never a hand-edit.
- If the task is about fresh GitHub intake or duplicate-prevention, start in the roadmap queue (via `releases roadmap list`), then follow the linked `PROJECT/1-INBOX/GH-*.md` capture doc.
- If the task is about document quality, active-doc lifecycle, roadmap sprawl, or automation policy, start in `PROJECT/PDDA.md`.
- If the task is about the CHANGELOG, provenance, or end-of-iteration logging, the governance is in `PROJECT/PDDA.md` (the "CHANGELOG.md — end-of-iteration record" contract).
- If the task is about release planning, ledger health, cleanup, authoring, or publishing, invoke `/releases`. It operates against `releases.db` via `releases_app.py`; `RELEASES.md` has been retired (GH-568). It conditionally points strategic drift to `/radar` and a frozen path-to-ship to `/finish-line` without duplicating either workflow.
- If the task is about the `tick` runtime, event projection, or multi-agent coordination kernel, start in `README.md`, then `bin/`, `src/`, `test/`, and the active project doc.
- If the task is about the **Aider ↔ OpenRouter** turn-taker lane (`relay-automation/aider-turn.sh` — an OpenAI-standard build lane discrete from Codex; `AIDER_MODEL`/`OPENROUTER_API_KEY`, `--builder aider`), start in `PROJECT/3-COMPLETED/GH-77-AIDER-OPENROUTER-LANE.md`. The shim owns the tick token ops (Aider can't run shell mid-turn), asserts token ownership before launching Aider, and runs Aider `--no-auto-commits` (the harness commits).
- If the task is about running, driving, or reviewing via the relay (`relay-automation/` — `relay-drive.sh`, `poll.sh`, the turn shims, `marathon*.sh`), **invoke the `relay-xyz` skill first — do not improvise the handoff or hand-roll a harness from `ls relay-automation/`.** The skill owns the locator, sandbox rules, exit codes, and the safety boundary; a `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) blocks driving a harness driver before the skill is loaded. For the two live-Claude-windows, same-machine duel recipe (Reporter↔Maintainer with a human go-gate), the copy-paste form is [relay-automation/DUELING-CLAUDES.md](relay-automation/DUELING-CLAUDES.md).
- If the task is about the ATE (Automated Testing Environment) skill — unattended variation-test fuzzing whose implementation lives under `utils/ate/` — start at its canonical interface in `skills/ate/SKILL.md`.
- If the task is about relay session telemetry, the `focus5float` health feed, or extraction scripts under `utils/telemetry/`, start in `PROJECT/1-INBOX/GH-24-RELAY-TELEMETRY-EXTRACTOR.md`.
- If the task is about live per-session completion telemetry — the `XYZ.json` log every relay/marathon/swarm session appends to at the harness repo root (schema: `harness`/`sessionId`/`health`/`title`/`description`/`updatedAt`), the shared writer `utils/telemetry/append-xyz-completion.sh`, or the shared health mapping `utils/telemetry/health-lib.sh` — start in `PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md`. `XYZ.json` is local + gitignored (machine-specific).
- If the task is about cross-repo HQ tooling (`utils/hq/` — `hq.sh` single-repo actions, `rollup.sh` the Obsidian daily ROADMAP rollup, `marathon-scan.sh` the cross-repo marathon-preflight aggregator, `hq-lib.sh` the shared repo registry), start in `PROJECT/3-COMPLETED/GH-27-ROADMAP-DASHBOARD.md` and `PROJECT/3-COMPLETED/GH-158-HQ-MARATHON-SCAN.md`. The two rollups are deliberately separate today (`rollup.sh` → Obsidian, generic; `marathon-scan.sh` → hub repo, preflight-aware) and are not yet bridged — tracked in `PROJECT/1-INBOX/GH-192-HQ-MARATHON-OBSIDIAN-ROLLUP.md`.
- If the task is about a proposed roadmap-steward agent, start here, then read `PROJECT/PDDA.md` and its `Proposed roadmap steward extension` section.
- If the task is about finding or picking a skill for a job, see `ARCHITECTURE.md` → "Skills Index" for a one-line inventory of every skill in `skills/`.
- If the task is about **managing skills for the system** — adding a skill to the machine-wide collection, deploying/refreshing/removing it across the configured app targets (`targets.json`, machine-local), or asking what is deployed — the mechanism is the `skills-army-hq` skill (`skills/skills-army-hq/SKILL.md`). `skills/` in this repo is the authoring source; the durable collection lives wherever `XYZ_SKILLS_ROOT` points (machine-local, never committed; falls back to `~/git-pulse-sync/Deployed Skills`), and only `intake.py` / `sync.py` mutate it or the app symlinks. Never hand-copy a skill folder into an app's skills directory.
- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the roadmap ledger queue immediately via `releases roadmap add` (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.
# Guiding Principles

North star for **XYZ Forge**, the multi-agent coordination harness behind the `tick` event-log kernel and `relay-automation/` relay stack. When a choice is unclear, the option that keeps agents synchronized, contained, and verifiable — without leaking or destroying work — wins. AGENTS.md is the behavioral playbook; ROUTER.md is the entry-point map; this is the *why*.

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

XYZ Forge is a local-first operations system for humans directing agents across their repositories:
capture → rate → plan → preflight → execute → gate → land → record. Its `tick` kernel coordinates
local claims through an event log and exclusive locks; its relay and Marathon tooling drive bounded
build and review work. Containment controls reduce accidental writes but do not guarantee safety
outside their enforced boundaries; linked worktrees share Git state. The product prioritizes
coordination, recoverability and verifiable outcomes. The operator remains the decision authority.

XYZ is not enterprise application lifecycle management or an agent marketplace. It currently
assumes specified work rather than providing a structured spec/PRD-generation pipeline of its own;
that capability gap is not a permanent prohibition on future product work. PDDA’s governance-layer
anti-scope does not prohibit XYZ’s coordination and execution features.

## The quality bar

Every agent turn is a signal. A turn is high-quality only when it is all four:

- **Attested** — carries its receipts: source, evidence, confidence. Never a bare verdict. A relay review names which claim is wrong and why; a build turn names the seam it touched.
- **Relevant** — ranked, not dumped. Volume is not value. One real bug beats five nits and a phantom.
- **Fresh** — current, not stale. A turn that reads a stale `STATE.md` or misses an epoch fence is wrong by construction.
- **Structured** — one shape, clean for the operator to read and for downstream agents to feed on.

Fail a pillar, and the turn, feature, or relay review isn't done.

## How it's built

1. **Coordination is local-transport only.** `.tick/events/` is the shared bus; claims resolve from there, not from a remote. No per-event push/fetch; no remote dependency at runtime. A coordination primitive that reaches out is a coordination primitive that can fail or leak.

2. **One canonical event log for tick coordination.** `.tick/events/` records coordination events; `.tick/STATE.md` is a derived view. Coordination verbs read and fold the events and append changes through the event API. Other subsystems retain their own documented sources of truth, including the RELEASES roadmap ledger. Do not create competing copies of canonical state.

3. **Containment is non-negotiable.** A headless turn must not: self-commit mid-turn, orphan a peer's concurrent commit, or write outside its allowlist. The allowlist, worktree isolation, and commit-bypass guard exist because a driven agent will do all three if unconstrained — not hypothetically, but as documented live incidents (GH-13, GH-14, GH-17). New relay paths must clear the containment bar before they ship.

4. **Skill-first; never improvise the harness.** The `relay-xyz` skill owns the locator, sandbox rules, exit codes, and the safety boundary. A session that improvises those from `ls relay-automation/` silently skips the skill's safety layer. In sessions that install and invoke the `PreToolUse` hook, `relay-automation/hooks/relay-xyz-guard.sh` checks supported driver invocations for the skill’s setup evidence; this is not a guarantee that every runtime invokes that hook. Add capabilities to the skill; do not work around it.

5. **Adversarially proven before commercially viable.** The harness exists to run against real codebases. Features in the adversarial-hardening track (epoch fencing, chaos suite, cross-repo E2E) must be verified to survive deliberate abuse — stale writers, zombie claims, macOS case-sensitivity, concurrent peer commits — not just the happy path. A feature that clears the happy path and skips chaos is half-done.

6. **Build durable, not band-aid.** Durable means it removes the root cause and the next planned change builds on it — not a patch torn out when the obvious next feature lands. A band-aid is wasted work unless a demo strictly needs one, and a demo band-aid is tagged for removal so it isn't silently inherited.

7. **Least code that clears the bar.** The `tick` coordination kernel uses Node's standard library. The repository also ships `package.json` and `package-lock.json` for Acorn-based source analysis. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.

8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.

9. **Docs support resumable work (PDDA).** ROUTER points to the governing contracts; the RELEASES DB owns this repository's roadmap ledger (queried via `python3 utils/py/releases_app.py roadmap list`). Linked PROJECT documents hold plans, decisions and handoff detail; CHANGELOG records dated outcomes. Resume execution using those documents together with the relevant runtime state and evidence. If current documentation contradicts the implementation, correct it or explicitly record the unresolved discrepancy.

10. **Done means verified.** "Done" is `validate.sh` green, the relevant PDDA checks passing, and any relay review returning `Approved` — not work that looks finished. An unverified success claim is itself a low-quality signal.

11. **Issue-first; every non-trivial change has a signal stream.** Any change beyond a 2–3 line fix opens a GitHub issue first, then gets a `GH-<number>` in-repo pointer doc, then lands. The issue is the machine-queryable signal stream; the `PROJECT/**` doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt.

12. **Independent Verification (Separated Grading)** — The agent that produces a turn must not be the sole grader of its own quality. Verification must be performed by an independent deterministic check or a separate reviewing agent before the lock releases. Applies to: the relay's structural block validator (`bin/validate-relay-block` — Phase 1 of GH-21), consult-verify diversity (Phase 3), and any other post-generation quality gate.

13. **A green gate without a witnessed red control is not evidence.** Every new or materially changed decision gate ships a recorded demonstration that it fails for the right reason: a pre-fix replay, deliberate mutation, or controlled bad fixture. Do not mistake a check that validates the artifact it just generated (#351) or a parity check that compares a lane to itself (#348) for evidence; both shapes are structurally unable to falsify their claim.

## Applying this

Adding a feature or weighing a tradeoff, ask: *does this keep agents coordinated without collision, contained within their scope, and verifiable to an outside observer? And is "done" provable by running `validate.sh`?* If any answer is no, reconsider.

---

## Conventions

### Strict-mode policy (bash `set -e`)

Python is the default implementation for the twelve frozen Tier-A entry points. Existing Bash
bodies are compatibility fallbacks selected with `XYZ_PYTHON=0`; their strict-mode choices remain
subsystem-specific. Consult each existing script’s header and error handling before changing it.
New executables under `utils/` or `relay-automation/` follow AGENTS.md’s Python and exception rules.
This section does not authorize edits to frozen Bash twins.

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

- **Builder default is `codex`.** Marathon’s current implementation defaults to Codex; agy is
  another supported builder. Choosing Claude remains an explicit, cost-acknowledged operator
  decision under AGENTS.md. Actual billing depends on the selected tool’s authentication and
  account configuration; a default executable name does not establish a billing guarantee. The
  Python implementation is the default, with the existing Bash fallback available through
  `XYZ_PYTHON=0`.
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
3. **Coordination through the event log?** Tick coordination state uses `tick` verbs; other subsystems use their documented canonical writers. Competing state copies need explicit justification.
4. **Done verifiable?** Names runnable gates (`validate.sh`, specific tests, `utils/pdda/pdda.sh run`). None = low-quality signal.
5. **Drift reduced, not created?** No duplicated docs, no execution detail in the roadmap ledger or its generated dashboard, no reinventing a path the event-log contract already documents.
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
- The roadmap ledger would need execution detail to make the plan legible.

exec
/bin/zsh -lc "rg -n \"role_note|scratch_note|XYZ_TOOL_MODE|full.*gate|validate\\.sh|rtl_enforce|\\.relay-scratch|dirty\" relay-automation/relay-turn-lib.sh && rg -n \"TAKE YOUR TURN|GH-268|GH-173|ROUND_CAP|Reviewer|Producer\" relay-automation/new-relay.sh && rg -n \"relay-turn-lib\\.sh|reviewer|scratch|contain\" relay-automation/README.md && rg -n \"relay-turn-lib|review|scratch|read.only|contain\" decisions/2026-06-15-unattended-agent-containment.md 2>/dev/null || true && python3 utils/py/releases_app.py roadmap list | rg -n \"681|relay|review\"" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-93733-mu26k550
 succeeded in 23ms:
24:rmi-01M0XY6RHQAK59HQ9N8YKM8J1J  GH-246  Completed              #14  cre=-      calc=250      🆕 relay-xyz SKILL.md: explicit QA/Consult prompt template for head
31:rmi-01M0QMC4DSR91AGC2Q54QYMBDV  GH-184  Completed              #19  cre=-      calc=270      ✅ GH-184 · committed scratch artifact `.relay-scratch/probe_teleme
43:rmi-01M0DP23VANQ7D8Y804WVDTEC7  GH-42   Completed              #23  cre=-      calc=185      ✅ GH-42 · relay automation: supported Commandcode turn-taker
55:rmi-01M0M0FPFTTE67F27VV3JGKNKC  GH-132  Completed              #31  cre=-      calc=275      ✅ GH-132 · feat(skills): formal /review-xyz code review skill & mu
62:rmi-01M1M3B6RQB0PQJK017M2RCHE2  GH-410  Completed              #35  cre=-      calc=305      🆕 relay-block validator never runs on the driven path
98:rmi-01M24H7Y3XMK9RN2G91SEJ0MJ0  GH-523  Completed              #70  cre=-      calc=300      ✅ merge-cleanup: primary on-disk checkout is not reviewed first; P
103:rmi-01M26ZN7GENTFNX6G72H97DDRC  GH-533  Completed              #71  cre=-      calc=364>91   ✅ Relay scaffold verdict vocabulary contradicts validate-relay-blo
105:rmi-01M272NGYED1BG31G7VDM051X2  GH-564  Completed              #72  cre=-      calc=240      ✅ work backfill from ledger state + a review_ready producer in rec
112:rmi-01M2F8VQSEE49D874K46CYFBQ2  GH-615  Completed              #74  cre=-      calc=-        ✅ fix(skills): reinforce start-task against relay-induced overbuil
113:rmi-01M2F9CCH0Q2R58G9F8MHJ22AK  GH-616  Completed              #74  cre=-      calc=-        ✅ fix(skills): enforce commensurate machinery and review-packet en
114:rmi-01M2FA4YHCYT94RN42QQXEXXYV  GH-617  Completed              #74  cre=-      calc=-        ✅ fix(skills): sharpen relay-xyz review scope against over-enginee
120:rmi-01M2HTFB2PQ87X0T3D4BZ4RPM6  GH-613  Completed              #75  cre=-      calc=270      ✅ Claude review follow-ups
122:rmi-01M2P55NBX57AA7FW8DP2XMVXB  GH-658  Completed              #86  cre=-      calc=8        ✅ Containment allowlist stores the ABSOLUTE relay_file path — work
131:rmi-01M216KYDGPSANYH09JDNBHCP3  GH-505  In progress            #63  cre=-      calc=275      🆕 Builder can approve and close its own relay; no merge path check
132:rmi-01M21BA8K8DX1RF4RBG6TZGXJA  GH-509  In progress            #64  cre=-      calc=235      🆕 Relay terminal authorization: prove a review happened without tr
160:rmi-01M1M0BT84BCG7MZTZXPSJKNYV  GH-406  Queue / parked intake  #34  cre=-      calc=13>4     🆕 External review (Russ K.): eight findings on guards that cover a
176:rmi-01M1YH2B00VZ5JJDYSTD3NNA89  GH-482  Queue / parked intake  #58  cre=-      calc=240      🆕 relay-drive.sh --artifact-file silently seeds nothing — the revi
184:rmi-01M223B5F08X7MRQQP3XEXBABM  GH-494  Queue / parked intake  #67  cre=-      calc=240      🆕 Flight dashboard HTML design review
188:rmi-01M2EAVGWSWD6978YJSEN29ES7  GH-608  Queue / parked intake  #72  cre=-      calc=8        🆕 fix(relay): honor Qwen/DeepSeek reasoning effort and correct fal
189:rmi-01M2EJD1147MEGR068N3KNJEXX  GH-610  Queue / parked intake  #73  cre=-      calc=8        🆕 feat(claude): subscription-validated native consult and relay su
190:rmi-01M2G8J65H17RBDH7297ZKFMD5  GH-589  Queue / parked intake  #74  cre=-      calc=170      🆕 Build XYZ mini: beginner-friendly stripped repo (relay, consult,
199:rmi-01M2KNNXMYT9BJM02JS3E26QAN  GH-606  Queue / parked intake  #83  cre=-      calc=230      🆕 End of Week governance review and kanban refresh
203:rmi-01M2PD8AVRRQZDFT25JS5VJATA  GH-663  Queue / parked intake  #88  cre=-      calc=8        🆕 QA findings (agy relay review) on the GH-654/658/659/660 hotfix 

exec
/bin/zsh -lc "nl -ba relay-automation/relay-turn-lib.sh | sed -n '340,395p;790,920p;1028,1072p;1058,1180p;1318,1405p'
nl -ba relay-automation/new-relay.sh | sed -n '1,115p'
nl -ba relay-automation/README.md | sed -n '18,35p;78,94p;285,315p;390,410p'
nl -ba decisions/2026-06-15-unattended-agent-containment.md | sed -n '1,260p'
nl -ba .gitignore | sed -n '1,180p'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-93733-mu26k550
 succeeded in 0ms:
   340	  # string yields the toplevel in RTL_ROOT's OWN symlink form, matching what the rest of the turn uses.
   341	  #
   342	  # GH-417 — scope of the warning above. It is about THIS collapse, which runs BEFORE the GH-261
   343	  # normalization below and would therefore change RTL_ROOT's symlink form while the allowlist is
   344	  # still holding the caller's. It is NOT a verdict on `--show-toplevel` generally, and in particular
   345	  # not on utils/py/rtl.py:resolve_turn_root, which defaults ROOT to exactly that construct on purpose
   346	  # (GH-296) and is safe doing so: GH-261 (312a2c3) canonicalizes BOTH RTL_ROOT and each absolute
   347	  # allowlist entry to physical form before stripping, so by then either form resolves. The two
   348	  # statements read as a contradiction for three weeks and cost Marathon Plan K's Wave 1 a wrong
   349	  # root-cause; 312a2c3's own message names the test/marathon-drive.sh GH-171/GH-172 failures Plan K
   350	  # measured two days earlier and could not explain. test/gh417-turn-root-symlink-prefix.sh pins all
   351	  # of it, including that removing GH-261's canonicalization brings exit 6 straight back.
   352	  local _gh160_prefix
   353	  _gh160_prefix="$(git -C "$RTL_ROOT" rev-parse --show-prefix 2>/dev/null)"
   354	  if [[ -n "$_gh160_prefix" ]]; then
   355	    _gh160_collapsed=1
   356	    RTL_ROOT="${RTL_ROOT%/"${_gh160_prefix%/}"}"
   357	  fi
   358	  # macOS/APFS (and any case-insensitive fs) reports git-status paths in the case the INDEX tracks
   359	  # (e.g. RELAY-SYSTEM/…), which can differ from the lowercase invocation arg the allowlist holds
   360	  # (relay-system/…). Detect it ONCE here so rtl_in_allow can compare case-insensitively on such
   361	  # filesystems (GH-17) — otherwise a reviewer's legit append to its own relay file is seen as
   362	  # off-allowlist and reverted with exit 6. Case-sensitive repos (Linux CI) keep a byte-for-byte
   363	  # exact compare. Non-repo / unset → false (the safe, case-sensitive default).
   364	  RTL_IGNORECASE="$(git -C "$RTL_ROOT" config --get core.ignorecase 2>/dev/null || echo false)"
   365	  [[ "$RTL_IGNORECASE" == "true" ]] || RTL_IGNORECASE=false
   366	  RTL_WT_USED=0          # set to 1 by rtl_worktree_begin; read by rtl_enforce's commit-bypass guard (GH-13)
   367	  RTL_ALLOW=("$f")
   368	  # REVIEWER-turn scoping: a reviewer is near read-only — it only APPENDS findings to the relay file
   369	  # and must never edit the artifact under review. When NEXT names the Reviewer, drop the caller's
   370	  # extra allowlist (relay file ONLY) so any artifact edit a headless reviewer makes is reverted by
   371	  # rtl_enforce. This is the boundary an over-eager agy reviewer crossed on 2026-06-20 (it edited
   372	  # validate.sh because the artifact sat on ALLOW_PATHS). Producer turns keep the full allowlist —
   373	  # they legitimately build.
   374	  # GH-173 B3: remember reviewer-turn-ness for rtl_enforce (called AFTER the turn, by which point the
   375	  # agent has already flipped NEXT to the other role — rtl_is_reviewer_turn "$f" would read false then).
   376	  if rtl_is_reviewer_turn "$f"; then
   377	    RTL_WAS_REVIEWER_TURN=1
   378	    [[ -n "$csv" ]] && printf 'relay-turn: REVIEWER turn — scoping allowlist to the relay file only (ignoring ALLOW_PATHS=%s)\n' "$csv" >&2
   379	    csv=""
   380	  else
   381	    RTL_WAS_REVIEWER_TURN=0
   382	  fi
   383	  local _extra p; IFS=',' read -ra _extra <<<"$csv"
   384	  for p in "${_extra[@]:-}"; do [[ -n "$p" ]] && RTL_ALLOW+=("$p"); done
   385	  # GH-261: RTL_ROOT and an absolute RTL_ALLOW entry (the relay file, typically) can each
   386	  # independently arrive in EITHER symlink form — e.g. RTL_ROOT via `git rev-parse --show-toplevel`
   387	  # (physical, /private/var/... on macOS) while the caller built the relay-file path from its own
   388	  # $PWD (logical, /var/...), or vice versa depending on which code path ran. Whichever direction
   389	  # the mismatch goes, the prefix strip below is a silent no-op: the entry survives absolute, fails
   390	  # its own off-lane match in rtl_worktree_end, and the whole turn is wrongly reverted as a
   391	  # containment violation (exit 6). Canonicalize BOTH sides to their physical form before stripping
   392	  # so either direction resolves; a genuinely foreign path (a real XYZ_ARCHIVE_ROOT redirect, GH-30
   393	  # Phase 3, below) still won't share RTL_ROOT's prefix even in physical form, so this is a no-op
   394	  # for that case — it stays absolute as intended.
   395	  local _rtl_root_phys
   790	    fi                                 # (Codex review r2, 2026-06-20 — symmetric to the in-turn delete)
   791	  done
   792	  # GH-22: snapshot each seeded allowlist path's signature so rtl_worktree_end copies back ONLY paths
   793	  # the turn modified in the worktree — an agent that wrote ROOT directly (real agy resolves the relay
   794	  # file to its absolute ROOT path even with CWD=worktree) must not be overwritten by the stale seed.
   795	  # Persist to a sidecar file (NOT inside the worktree — that would read as an off-lane untracked file)
   796	  # because the caller invokes this via wt="$(rtl_worktree_begin)", a subshell whose globals are lost;
   797	  # rtl_worktree_end re-reads the sidecar by the worktree path it is handed. One line per RTL_ALLOW entry.
   798	  : >"${wt}.seedsig"
   799	  for a in "${RTL_ALLOW[@]}"; do [[ "$a" == /* ]] && continue; _rtl_sig "$wt/$a" >>"${wt}.seedsig"; done
   800	  # GH-31 / #15: seed the read-only artifact under review so an ISOLATED reviewer can READ it (it is
   801	  # neither at HEAD nor on the writable allowlist). Snapshot the .relay-artifacts dir signature to a
   802	  # sidecar so rtl_worktree_end can exempt it from off-lane detection ONLY while unchanged — a reviewer
   803	  # edit changes the signature and trips off-lane (strict read-only). NOT in RTL_ALLOW ⇒ never copied back.
   804	  if [[ -n "${RTL_ARTIFACT:-}" && -f "$RTL_ARTIFACT" ]]; then
   805	    mkdir -p "$wt/.relay-artifacts"
   806	    cp "$RTL_ARTIFACT" "$wt/$RTL_ARTIFACT_REL"
   807	    # GH-505: the driver digested the artifact BEFORE dispatch; the bytes seeded here must be those
   808	    # bytes, or the record would describe an input the reviewer never saw. Refuse disagreement.
   809	    if [[ -n "${RELAY_ARTIFACT_SHA256:-}" ]]; then
   810	      local _seeded_sha
   811	      _seeded_sha="$(shasum -a 256 "$wt/$RTL_ARTIFACT_REL" 2>/dev/null | cut -d' ' -f1)"
   812	      if [[ "$_seeded_sha" != "$RELAY_ARTIFACT_SHA256" ]]; then
   813	        printf 'rtl_worktree_begin: seeded artifact digest %s != driver digest %s — source changed between dispatch and seed; refusing the turn\n' "${_seeded_sha:0:12}" "${RELAY_ARTIFACT_SHA256:0:12}" >&2
   814	        git -C "$RTL_ROOT" worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"
   815	        return 1
   816	      fi
   817	    fi
   818	    _rtl_sig "$wt/.relay-artifacts" >"${wt}.artifactsig"
   819	  fi
   820	  # GH-91: the sanctioned scratch dir. The harness REQUIRES the builder to verify its work by
   821	  # running commands that produce output, so it owes the turn a place inside the tree to put
   822	  # that output — the 0.7.2 daybreak re-fire reverted four green probe JSONs as off-lane and
   823	  # failed a complete, passing turn at exit 6. Pre-created (the affordance physically exists),
   824	  # named in rtl_turn_prompt, exempted by rtl_worktree_end/rtl_check, never copied back, and
   825	  # discarded with the worktree.
   826	  mkdir -p "$wt/.relay-scratch"
   827	  RTL_WT="$wt"; RTL_WT_USED=1   # GH-13: mark the turn worktree-isolated so rtl_enforce won't reset a concurrent peer's ROOT commit
   828	  printf '%s\n' "$wt"
   829	}
   830	
   831	
   832	xyz_write_ops_log_append() {
   833	  [ "${XYZ_WRITE_OPS_LOG:-}" = "0" ] && return 0
   834	  local dest="${XYZ_WRITE_OPS_LOG:-$HOME/.local/state/xyz/write-ops.jsonl}"
   835	  local pattern="$1"
   836	  local cmd="$2"
   837	  local stamp; stamp="$(date -u +'%Y%m%dT%H%M%SZ')"
   838	  local host; host="$(hostname)"
   839	  local cwd; cwd="$(pwd)"
   840	  python3 -c '
   841	import sys, json, os
   842	record = {
   843	    "timestamp": sys.argv[1],
   844	    "host": sys.argv[2],
   845	    "session": os.environ.get("TERM_SESSION_ID", ""),
   846	    "cwd": sys.argv[3],
   847	    "pattern": sys.argv[4],
   848	    "command": sys.argv[5],
   849	    "stage": "run"
   850	}
   851	log_path = sys.argv[6]
   852	try:
   853	    os.makedirs(os.path.dirname(log_path), exist_ok=True)
   854	    fd = os.open(log_path, os.O_CREAT | os.O_WRONLY | os.O_APPEND, 0o600)
   855	    with os.fdopen(fd, "a") as f:
   856	        f.write(json.dumps(record) + "\n")
   857	except Exception:
   858	    pass
   859	' "$stamp" "$host" "$cwd" "$pattern" "$cmd" "$dest" || true
   860	}
   861	
   862	rtl_worktree_end() {  # [<wt>] — sets RTL_WT_OFFLANE (0|1); copies allowlist back unless off-lane found
   863	  # Contain + DETECT: if the agent touched anything outside {allowlist, .tick} in the worktree, that's
   864	  # an off-lane attempt — do NOT copy anything back (the turn must fail like an in-ROOT exit-6), set
   865	  # RTL_WT_OFFLANE=1, and destroy the worktree. Otherwise copy ONLY the allowlist back to RTL_ROOT —
   866	  # edits/creates propagate, AND an allowlisted path the turn DELETED in the worktree is removed from
   867	  # RTL_ROOT too (so an isolated Producer that deletes an artifact isn't silently undone — Codex review
   868	  # 2026-06-20) — then destroy the worktree.
   869	  local wt="${1:-${RTL_WT:-}}" a entry xy path
   870	  RTL_WT_OFFLANE=0
   871	  [[ -n "$wt" && -d "$wt" ]] || return 0
   872	  rtl_trace "rtl_worktree_end: WT=$wt"
   873	  # GH-266: the harness's own transcript-log directory, when NOT redirected via XYZ_ARCHIVE_ROOT (the
   874	  # default), lives inside RTL_ROOT itself and is genuinely new/untracked in a fresh isolated worktree
   875	  # — exempt it the same way .tick/ is exempted below, mirroring rtl_check()'s $RTL_LOG_REL exemption
   876	  # (line ~683). When XYZ_ARCHIVE_ROOT IS set, rtl_transcript_root resolves outside RTL_ROOT entirely,
   877	  # so nothing here would ever appear in this worktree's own git status — no exemption needed then.
   878	  local _rtl_log_top=""
   879	  [[ -z "${XYZ_ARCHIVE_ROOT:-}" ]] && _rtl_log_top="$(basename "$(rtl_transcript_root "$RTL_ROOT")")"
   880	  # GH-13/#14: rtl_worktree_begin runs in a `wt="$(...)"` subshell, so the RTL_WT_USED=1 it sets there
   881	  # is LOST before rtl_enforce runs — which left the "a moved ROOT HEAD is a concurrent PEER commit;
   882	  # preserve it, don't reset" branch in rtl_enforce as DEAD CODE for the command-substitution shims
   883	  # (codex/agy). Every moved ROOT HEAD then wrongly hit the in-ROOT reset+exit-6 path, discarding a
   884	  # worktree builder's whole turn (the 2026-06-29 codex marathon, #14). This function runs in the
   885	  # caller's shell and is always reached before rtl_enforce for a worktree turn, so re-assert the flag
   886	  # here to restore the GH-13 protection. (The agent ran CWD=worktree, so its OWN commits can't reach
   887	  # ROOT; a moved ROOT HEAD is genuinely a peer/harness commit. Off-lane worktree content is already
   888	  # contained below before rtl_enforce sees it.)
   889	  RTL_WT_USED=1
   890	  while IFS= read -r -d '' entry; do
   891	    [[ -n "$entry" ]] || continue
   892	    xy="${entry:0:2}"; path="${entry:3}"
   893	    case "$xy" in R*|C*) IFS= read -r -d '' _ || true ;; esac   # rename/copy: consume 2nd NUL field
   894	    case "$path" in .tick/*|.tick) continue ;; esac
   895	    # GH-91: builder scratch / verification output — sanctioned, writable by design, exempt with
   896	    # NO signature check (unlike .relay-artifacts above: scratch is meant to be written), never
   897	    # copied back (the copyback loop iterates RTL_ALLOW only), discarded with the worktree.
   898	    case "$path" in .relay-scratch|.relay-scratch/|.relay-scratch/*) continue ;; esac
   899	    # GH-266: git collapses an all-untracked dir to one line (same reasoning as .relay-artifacts
   900	    # below) — match both the bare transcript-log directory name and any path under it.
   901	    if [[ -n "$_rtl_log_top" ]]; then
   902	      case "$path" in "$_rtl_log_top"|"$_rtl_log_top"/|"$_rtl_log_top"/*) continue ;; esac
   903	    fi
   904	    # GH-31 / #15: the read-only artifact seed. Exempt ONLY while unchanged from the seed; a reviewer
   905	    # edit changes the .relay-artifacts dir signature → strict-fail as off-lane (read-only enforced,
   906	    # not silently discarded). git collapses an all-untracked dir to ".relay-artifacts/", so match both.
   907	    case "$path" in
   908	      .relay-artifacts|.relay-artifacts/|.relay-artifacts/*)
   909	        if [[ -f "${wt}.artifactsig" ]] && [[ "$(_rtl_sig "$wt/.relay-artifacts")" == "$(cat "${wt}.artifactsig")" ]]; then
   910	          continue
   911	        fi
   912	        rtl_trace "rtl_worktree_end: OFFLANE path=$path (artifact modified)"
   913	        RTL_WT_OFFLANE=1; continue ;;
   914	    esac
   915	    rtl_in_allow "$path" && continue
   916	    rtl_is_containment_ignored "$path" && continue   # GH-107: opt-in tool-cache exemption
   917	    # GH-113: same scratch relocation as rtl_check's non-worktree path — a scratch-shaped untracked
   918	    # root file in the throwaway worktree is moved into RTL_ROOT's .tick/scratch for inspection
   919	    # (the worktree itself is destroyed below, which would otherwise destroy the evidence) and the
   920	    # turn is NOT failed on it.
  1028	    fi
  1029	  fi
  1030	  if [[ -n "$csv" ]]; then
  1031	    IFS=',' read -ra _a <<<"$csv"
  1032	    for p in "${_a[@]}"; do [[ -n "$p" ]] && csv_rel+="${csv_rel:+,}${p#"${root:+$root/}"}"; done
  1033	  fi
  1034	  # REVIEWER-turn scoping: drop the csv from the "edit only" clause and tell the model plainly it must
  1035	  # not edit the artifact — so the prompt matches the relay-file-only allowlist rtl_init enforces (an
  1036	  # agent told it MAY edit X and then reverted is needless friction; tell it the truth up front).
  1037	  local role_note=""
  1038	  # GH-397: pass the acting agent explicitly — $1 here is the turn's real actor, so the role lookup
  1039	  # never has to fall back to the RELAY_AGENT env or to agent-maintained NEXT: prose.
  1040	  if rtl_is_reviewer_turn "$f" "$agent"; then
  1041	    csv_rel=""
  1042	    role_note=' You are the REVIEWER this turn: do NOT edit, create, or run any artifact or source file — ONLY append your graded findings to the relay file. Any other edit will be reverted and fail the turn. When approving, hand the token off with done and set STATUS: Approved.'
  1043	  fi
  1044	  # GH-31 / #15: point the reviewer at the seeded read-only artifact (worktree-relative; it is NOT a
  1045	  # writable edit target — an edit fails the turn).
  1046	  local art_note=""
  1047	  [[ -n "${RTL_ARTIFACT_REL:-}" ]] && art_note=" The artifact under review is at ${RTL_ARTIFACT_REL} — READ it for your review, but do NOT edit it (any edit fails your turn)."
  1048	  # GH-91: name the scratch affordance at the point of use — prose in a phase brief ("use \$TMPDIR")
  1049	  # is exactly what the daybreak builder ignored while doing precisely what it was asked to.
  1050	  local scratch_note=" Verification output (probe results, generated JSON, logs) goes under .relay-scratch/ — pre-created for you, exempt from containment, never copied back; scratch files anywhere else in the tree are reverted and FAIL your turn."
  1051	  local prog_note=""
  1052	  if [[ "${XYZ_TOOL_MODE:-${RELAY_TOOL_MODE:-}}" == "programmatic" ]]; then
  1053	    prog_note=" Programmatic tool mode is enabled: diagnostic Python scripts may be executed via script_runner.py with output directed to .relay-scratch/."
  1054	  fi
  1055	  printf 'You are agent %s, taking your turn in a file-based relay. Read %s and follow its embedded "\xe2\x96\xb6 TAKE YOUR TURN" steps for your role. For the %s token ALWAYS use the absolute, env-pinned tick — a bare or ./bin/tick from a worktree/foreign CWD silently no-ops and DEADLOCKS the relay: TICK_REPO_ROOT="%s" "%s". Token sequence: (1) claim it FIRST — claim %s --agent %s --paths %s — the --paths flag is MANDATORY; without it the claim silently fails (prints usage) and your later release errors "task ... is open". (2) ping is optional. (3) when finished, %s. Edit ONLY %s%s.%s%s NEVER run git yourself — no add/commit/push/reset; a self-commit FAILS your whole turn. Do NOT touch any other file. The harness makes the one file-scoped commit for you after you hand off the token. Do NOT run the full project test/gate suite (e.g. validate.sh) yourself — running it can create files that trip containment and DISCARD your whole turn; verify ONLY with the specific test for the file(s) you changed. The harness runs the gate after your turn.%s%s' \
  1056	    "$agent" "$f_rel" "$task" "$tickroot" "$tickbin" "$task" "$agent" "$f_rel" "$handoff" "$f_rel" "${csv_rel:+ and: $csv_rel}" "$role_note" "$art_note" "$scratch_note" "$prog_note"
  1057	}
  1058	
  1058	
  1059	rtl_before() {
  1059	rtl_before() {
  1060	  RTL_BEFORE_HEAD="$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)"
  1060	  RTL_BEFORE_HEAD="$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)"
  1061	  # Snapshot the PRE-turn dirty set (raw -z porcelain fields) so enforcement touches only the
  1061	  # Snapshot the PRE-turn dirty set (raw -z porcelain fields) so enforcement touches only the
  1062	  # agent's OWN changes — never pre-existing ambient WIP in the host repo (field report MBP16 [1]).
  1062	  # agent's OWN changes — never pre-existing ambient WIP in the host repo (field report MBP16 [1]).
  1063	  RTL_BEFORE=()
  1063	  RTL_BEFORE=()
  1064	  local fld
  1064	  local fld
  1065	  while IFS= read -r -d '' fld; do RTL_BEFORE+=("$fld"); done \
  1065	  while IFS= read -r -d '' fld; do RTL_BEFORE+=("$fld"); done \
  1066	    < <(git -C "$RTL_ROOT" status --porcelain -z 2>/dev/null)
  1066	    < <(git -C "$RTL_ROOT" status --porcelain -z 2>/dev/null)
  1067	
  1067	
  1068	  # GH-124 QW4: Early Rebase Drift Alert (Option A: zero-lock local tracking ref inspection)
  1068	  # GH-124 QW4: Early Rebase Drift Alert (Option A: zero-lock local tracking ref inspection)
  1069	  local drift_count
  1069	  local drift_count
  1070	  drift_count="$(git -C "${RTL_ROOT:-.}" rev-list --count HEAD..refs/remotes/origin/development 2>/dev/null || echo 0)"
  1070	  drift_count="$(git -C "${RTL_ROOT:-.}" rev-list --count HEAD..refs/remotes/origin/development 2>/dev/null || echo 0)"
  1071	  if [ "${drift_count:-0}" -ge 3 ]; then
  1071	  if [ "${drift_count:-0}" -ge 3 ]; then
  1072	    printf '%s-turn: ⚠️  NOTICE: tracking ref origin/development is %d commits ahead. Consider rebasing between phases.\n' \
  1072	    printf '%s-turn: ⚠️  NOTICE: tracking ref origin/development is %d commits ahead. Consider rebasing between phases.\n' \
  1073	      "${RTL_TOOL:-relay}" "$drift_count" >&2
  1074	  fi
  1075	}
  1076	
  1077	rtl_was_dirty_before() {  # <porcelain-entry> — true if this exact status+path was dirty pre-turn
  1078	  local e="$1" b
  1079	  for b in ${RTL_BEFORE[@]+"${RTL_BEFORE[@]}"}; do [[ "$b" == "$e" ]] && return 0; done
  1080	  return 1
  1081	}
  1082	
  1083	# GH-141 — recoverability-only mitigation for the concurrent peer-edit race.
  1084	#
  1085	# rtl_check CANNOT distinguish "a peer session's concurrent mid-turn edit" from "the agent's own
  1086	# off-lane self-escape": both produce byte-identical porcelain diffs, and rtl_before's snapshot is
  1087	# taken once at turn start, so anything that turns dirty DURING the turn window looks identical.
  1088	# Any fix of the shape "don't revert a newly-dirty non-allowlisted path" would silently disable
  1089	# rtl_enforce's documented backstop against the already-observed GH-22 self-escape vector.
  1090	#
  1091	# So the revert DECISION IS DELIBERATELY UNCHANGED. This only copies the pre-revert content aside
  1092	# first, turning "not recoverable in general" (GH-141's live 2026-07-05 incident, and a second
  1093	# occurrence on 2026-07-18) into a recoverable one. Mirrors the refs/relay-orphan/<sha> pattern
  1094	# rtl_enforce already uses for the moved-HEAD case. Backups land under .tick/, which rtl_check
  1095	# exempts intrinsically, so a backup can never itself be flagged as off-lane.
  1096	rtl_orphan_backup() {  # <path> — copy pre-revert content aside; must never block the revert
  1097	  local p="$1" dest
  1098	  [[ -n "$p" && -e "$RTL_ROOT/$p" ]] || return 0
  1099	  : "${RTL_ORPHAN_BACKUP:="$RTL_ROOT/.tick/orphan-backups/$(date -u +%Y%m%dT%H%M%SZ)-$$"}"
  1100	  dest="$RTL_ORPHAN_BACKUP/$p"
  1101	  mkdir -p "$(dirname "$dest")" 2>/dev/null || return 0
  1102	  cp -R "$RTL_ROOT/$p" "$dest" 2>/dev/null || return 0
  1103	  printf '%s-turn: pre-revert copy of %s saved under %s\n' "$RTL_TOOL" "$p" "$RTL_ORPHAN_BACKUP" >&2
  1104	  rtl_log_always "rtl_check: orphan-backup path=$p dest=$RTL_ORPHAN_BACKUP"
  1105	}
  1106	
  1107	# GH-113 — relocate, don't fail, the headless builder's root-level scratch.
  1108	#
  1109	# The observed incident (marathon/daybreak-wave-2, 2026-08-20): the agy builder wrote fix_lens1.py /
  1110	# test_lens6.py / tmp.json into the working-tree ROOT while debugging, rtl_check reverted them at
  1111	# exit 6, and a turn whose actual lane work was fine died on incidental scratch. Prose in the prompt
  1112	# is not a guarantee the builder model weights, so this is the mechanical half of the fix: a
  1113	# scratch-SHAPED write is moved into the sanctioned scratch lane and the turn proceeds.
  1114	#
  1115	# Deliberately NARROW — this is a room, not an amnesty (same line GH-91 drew for .relay-scratch):
  1116	#   - ROOT-LEVEL only (no "/" in the path): the incident shape is a transient script dropped in the
  1117	#     tree root; a nested off-lane path is a lane mistake, not scratch, and still violates.
  1118	#   - UNTRACKED only: an edit to a TRACKED file is an off-lane content change whatever its name —
  1119	#     the GH-22 self-escape backstop must keep biting there (GH-113 acceptance pins this).
  1120	#   - NAME must look like transient scratch (tmp*/temp*/scratch*/debug*/test_*/fix_*/repro_*/probe_*
  1121	#     prefix, or *.tmp/*.temp/*.bak/*.orig/~ suffix). "offlane.md" and friends still violate.
  1122	# The destination is .tick/scratch/ (exempted intrinsically, never rides into a commit, recoverable
  1123	# for inspection) — NOT .relay-scratch/, which rtl_enforce sweeps at end of turn and which would
  1124	# therefore destroy the evidence this function exists to preserve.
  1125	rtl_scratch_relocate() {  # <path> <src-root> [dest-root] — 0 = relocated, 1 = not scratch-shaped
  1126	  local p="$1" src_root="$2" dest_root="${3:-$2}" dest
  1127	  [[ -n "$p" && -n "$src_root" ]] || return 1
  1128	  case "$p" in ""|.|..|*/*|.*) return 1 ;; esac
  1129	  [[ "$p" =~ ^(tmp|temp|scratch|debug|test_|fix_|repro_|probe_) ]] \
  1130	    || [[ "$p" =~ \.(tmp|temp|bak|orig)$ ]] \
  1131	    || [[ "$p" == *~ ]] \
  1132	    || return 1
  1133	  git -C "$src_root" ls-files --error-unmatch -- "$p" >/dev/null 2>&1 && return 1
  1134	  [[ -e "$src_root/$p" ]] || return 1
  1135	  dest="${RTL_SCRATCH_DIR:="${dest_root:?}/.tick/scratch/$(date -u +%Y%m%dT%H%M%SZ)-$$"}"
  1136	  mkdir -p "$dest" 2>/dev/null || return 1
  1137	  mv "$src_root/$p" "$dest/$p" 2>/dev/null || return 1
  1138	  printf '%s-turn: SCRATCH RELOCATION (GH-113): untracked root-level %s moved to %s — turn NOT failed. Write scratch under $TMPDIR or .relay-scratch/ instead.\n' \
  1139	    "${RTL_TOOL:-relay}" "$p" "$dest" >&2
  1140	  rtl_log_always "rtl_scratch_relocate: path=$p src=$src_root dest=$dest (GH-113)"
  1141	  return 0
  1142	}
  1143	
  1144	rtl_check() {  # <path> — reads RTL_ROOT/RTL_LOG_REL/RTL_TOOL, sets RTL_VIOLATION
  1145	  local p="$1"
  1146	  [[ -n "$p" ]] || return 0
  1147	  # tick's own state dir is coordination state the turn legitimately writes — exempt it intrinsically,
  1148	  # independent of whether the HOST repo gitignores .tick (field report MBP16 [2]).
  1149	  case "$p" in .tick/*|.tick) return 0 ;; esac
  1150	  # GH-91: same sanction on the non-worktree path, but here the dir lives in RTL_ROOT itself —
  1151	  # exempt AND discard (the transcript-log drop below is the precedent, not the .tick leave-in):
  1152	  # scratch is consumed by the turn that wrote it and must neither ride into a commit nor linger
  1153	  # in the tree. ${RTL_ROOT:?} because rm -rf on an empty-prefix path would target /. — GH-567.
  1154	  case "$p" in .relay-scratch|.relay-scratch/|.relay-scratch/*)
  1155	    rm -rf "${RTL_ROOT:?}/.relay-scratch"
  1156	    return 0
  1157	  ;; esac
  1158	  # the shim's own transcript log, if it lands in the tree, is not an agent edit — drop it, don't flag
  1159	  if [[ -n "$RTL_LOG_REL" && "$p" == "$RTL_LOG_REL" ]]; then rm -f "$RTL_ROOT/$p"; return 0; fi
  1160	  # GH-261: the exact-match exemption above only fires for the ONE transcript file itself; when the
  1161	  # harness's own transcript-log directory is entirely new/untracked, git collapses it to one line
  1162	  # (e.g. "relay-system/"), which never equals $RTL_LOG_REL's deeper file path. Mirrors
  1163	  # rtl_worktree_end's GH-266 fix, applied here to the non-worktree containment path too.
  1164	  if [[ -z "${XYZ_ARCHIVE_ROOT:-}" ]]; then
  1165	    local _rtl_log_top; _rtl_log_top="$(basename "$(rtl_transcript_root "$RTL_ROOT")")"
  1166	    case "$p" in "$_rtl_log_top"|"$_rtl_log_top"/|"$_rtl_log_top"/*) return 0 ;; esac
  1167	  fi
  1168	  if rtl_in_allow "$p"; then
  1169	    rtl_trace "rtl_check: ALLOW path=$p"
  1170	    return 0
  1171	  fi
  1172	  # GH-113: scratch-shaped untracked root files relocate instead of violating — AFTER the allowlist
  1173	  # check so an explicitly allowlisted path keeps its normal handling, and BEFORE the revert so the
  1174	  # turn is not failed on transient scratch.
  1175	  rtl_scratch_relocate "$p" "$RTL_ROOT" && return 0
  1176	  printf '%s-turn: OFF-ALLOWLIST change: %s — reverting\n' "$RTL_TOOL" "$p" >&2
  1177	  rtl_log_always "rtl_check: OFF-ALLOWLIST path=$p tool=$RTL_TOOL — reverting"
  1178	  rtl_offlane_hint "$p"    # GH-90: name a file-vs-directory lane-spec mistake before the revert
  1179	  rtl_orphan_backup "$p"   # GH-141: recoverable copy BEFORE the destructive revert below
  1180	  git -C "$RTL_ROOT" checkout -- "$p" 2>/dev/null || rm -rf "$RTL_ROOT/${p%/}"
  1318	        if (echoed_token != "") print "ECHOED " echoed_token
  1319	        else print "FIRSTHAND " first_token
  1320	      }
  1321	    }
  1322	  ' "$prompt" "$transcript"
  1323	}
  1324	
  1325	rtl_enforce() {  # <task> <agent> <log> <tool>
  1326	  local task="$1" agent="$2" log="$3"; RTL_TOOL="$4"
  1327	  # (2) commit-bypass guard: the agent must NOT git. If HEAD moved, its edits are hidden from
  1328	  # `git status` — undo the commit(s) and fail, so off-lane changes can't slip in committed.
  1329	  if [[ "$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)" != "$RTL_BEFORE_HEAD" ]]; then
  1330	    if [[ "${RTL_WT_USED:-0}" == "1" ]]; then
  1331	      # GH-13: this turn ran in a throwaway worktree, so the agent CANNOT have moved ROOT's HEAD — a
  1332	      # moved ROOT HEAD is therefore a CONCURRENT PEER commit. Never reset it: a blind `reset --hard`
  1333	      # here orphaned a peer agent's commit on 2026-06-23 (recovered via reflog). The agent's own writes
  1334	      # were already contained by rtl_worktree_end (off-lane → exit 6; else allowlist copyback), so just
  1335	      # preserve the peer commit and fall through to allowlist enforcement + a file-scoped commit ON TOP.
  1336	      printf '%s-turn: ROOT HEAD moved during a worktree-isolated turn — a concurrent peer committed; preserving it (not resetting), committing this turn on top.\n' "$RTL_TOOL" >&2
  1337	      rtl_log_always "rtl_enforce: HEAD_MOVED branch=peer-preserve (worktree-isolated; concurrent peer commit kept)"
  1338	    else
  1339	      # In-ROOT (direct/attended) turn: the agent ran in ROOT and may have committed off-lane changes.
  1340	      # Undo its commit and fail — the documented attended-mode containment. A concurrent PEER commit in
  1341	      # this mode is indistinguishable from a self-commit here, so before discarding it we save the
  1342	      # current HEAD under refs/relay-orphan/<sha>: the reset abandons it from the branch, but the ref
  1343	      # keeps it reachable, so a wrongly-caught peer commit is never lost (recover via
  1344	      # `git log refs/relay-orphan/*`). The default DRIVEN path uses worktree isolation (handled above);
  1345	      # this is the cheap backstop for the in-ROOT path (GH-13, relay review 2026-06-23 F6).
  1346	      git -C "$RTL_ROOT" update-ref "refs/relay-orphan/$(git -C "$RTL_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)" HEAD 2>/dev/null || true
  1347	      git -C "$RTL_ROOT" reset --hard "$RTL_BEFORE_HEAD" >/dev/null 2>&1 || true
  1348	      printf '%s-turn: %s committed during its turn (forbidden) — reset to %s (prior HEAD saved to refs/relay-orphan/), failing\n' "$RTL_TOOL" "$agent" "${RTL_BEFORE_HEAD:0:8}" >&2
  1349	      rtl_log_always "rtl_enforce: HEAD_MOVED branch=in-root-reset agent=$agent reset_to=${RTL_BEFORE_HEAD:0:8}"
  1350	      exit 6
  1351	    fi
  1352	  fi
  1353	  # (1) allowlist enforcement on tracked-tree changes (.tick is gitignored, so token ops don't show).
  1354	  # -z = NUL-delimited RAW unquoted paths (spaces/special chars can't slip the match or break the
  1355	  # revert); rename/copy records (R/C) carry a second NUL field — check both old+new. We deliberately
  1356	  # do NOT `git clean -Xdf` (it would wipe .tick, the coordination state the turn legitimately writes);
  1357	  # ignored-file safety belongs to the agent sandbox, tracked as future.
  1358	  RTL_LOG_REL="${log:+${log#"$RTL_ROOT"/}}"
  1359	  RTL_VIOLATION=0
  1360	  # Pre-existing ambient WIP (same status+path as before the turn) is left untouched, never failed.
  1361	  # (Documented minor gap: a file already dirty that the agent edits further to the SAME status code
  1362	  # isn't caught — acceptable for review turns.)
  1363	  local entry xy path src
  1364	  while IFS= read -r -d '' entry; do
  1365	    [[ -n "$entry" ]] || continue
  1366	    xy="${entry:0:2}"; path="${entry:3}"
  1367	    case "$xy" in
  1368	      R*|C*)
  1369	        IFS= read -r -d '' src || true
  1370	        # A rename counts as pre-existing only if BOTH dest and src were dirty before — else enforce
  1371	        # both paths. Prevents a staged rename whose dest matches an ambient rename's dest from hiding
  1372	        # a clean file's move/deletion via the src field (Gemini review 2026-06-15, rename-hijack).
  1373	        if rtl_was_dirty_before "$entry" && rtl_was_dirty_before "$src"; then continue; fi
  1374	        rtl_check "$path"; rtl_check "$src"
  1375	        ;;
  1376	      *)
  1377	        rtl_was_dirty_before "$entry" && continue
  1378	        rtl_check "$path"
  1379	        ;;
  1380	    esac
  1381	  done < <(git -C "$RTL_ROOT" status --porcelain -z)
  1382	  # GH-91 (PR #93 review): scratch must not survive the turn EVEN WHEN the host repo gitignores
  1383	  # it — porcelain omits ignored paths, so the per-path rtl_check discard above never fires and
  1384	  # the dir lingered in ROOT forever. Sweep unconditionally, independent of git visibility.
  1385	  [[ -d "${RTL_ROOT:?}/.relay-scratch" ]] && rm -rf "${RTL_ROOT:?}/.relay-scratch"
  1386	  rtl_trace "rtl_enforce: RTL_VIOLATION=$RTL_VIOLATION"
  1387	  ((RTL_VIOLATION == 0)) || { printf '%s-turn: off-lane edits reverted; failing the turn\n' "$RTL_TOOL" >&2; rtl_log_always "rtl_enforce: VIOLATION off-lane edits reverted; failing the turn"; exit 6; }
  1388	  # GH-173 B3: downgrade any uncited [Pass]/verified Reviewer finding BEFORE staging, so the fix lands
  1389	  # in the SAME commit as the turn instead of needing a second one. Reviewer-only (Producer findings
  1390	  # aren't graded by this template); RTL_WAS_REVIEWER_TURN was captured in rtl_init, before NEXT flipped.
  1391	  if [[ "${RTL_WAS_REVIEWER_TURN:-0}" == "1" && -n "${RELAY_FILE:-}" ]]; then
  1392	    rtl_check_uncited_findings "$RELAY_FILE"
  1393	    rtl_trace "rtl_enforce: checked $RELAY_FILE for uncited [Pass]/verified findings"
  1394	  fi
  1395	  # GH-410 / GH-21 / AGENTS.md §12: structural relay-block validation before staging.
  1396	  # The Reviewer turn must append a structurally valid review block (STATUS not In Progress,
  1397	  # ## Log present, VERDICT, and Basis).
  1398	  # If validation fails, exit 8 (relay block structural validation failed) so the harness
  1399	  # escalates rather than staging/committing a malformed block or handing off an invalid turn.
  1400	  if [[ "${RTL_WAS_REVIEWER_TURN:-0}" == "1" && -n "${RELAY_FILE:-}" ]]; then
  1401	    local _val_rf="${RELAY_FILE:-}" _val_tickroot="${TICK_REPO_ROOT:-${RTL_ROOT:-}}"
  1402	    if [[ "$_val_rf" != /* && ! -f "$_val_rf" ]]; then
  1403	      if [[ -f "$_val_tickroot/$_val_rf" ]]; then
  1404	        _val_rf="$_val_tickroot/$_val_rf"
  1405	      elif [[ -f "$RTL_ROOT/$_val_rf" ]]; then
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# new-relay.sh — scaffold a single-artifact review relay thread (GH-31 Phase 4).
     5	#
     6	# Emits a relay thread the harness can drive: NEXT:/STATUS: header, a "▶ TAKE YOUR TURN" block, a
     7	# Setup that names the artifact under review, ground rules, and an empty Log with the next-turn marker.
     8	#
     9	# Two artifact modes:
    10	#   (default, reference) — the Setup points at .relay-artifacts/<basename>, the read-only path that
    11	#       `relay-drive.sh --artifact-file <source>` seeds into the isolated worktree (GH-31 Phase 2 / #15).
    12	#   --embed              — inline the artifact's bytes in a FENCE-SAFE code block (GH-31 Phase 3): the
    13	#       fence is chosen LONGER than the longest backtick run inside the file, so an artifact that itself
    14	#       contains ```fenced``` markdown can't break out of the block.
    15	#
    16	# Usage:
    17	#   relay-automation/new-relay.sh --title T --reviewer AGENT [--artifact-file P] [--embed]
    18	#       [--producer AGENT] [--round-cap N] [--slug S] [--out PATH | --print]
    19	#
    20	# Exit: 0 ok · 2 usage.
    21	
    22	die() { printf 'new-relay: %s\n' "$*" >&2; exit 2; }
    23	
    24	TITLE="" REVIEWER="" PRODUCER="claude-a" ARTIFACT="" EMBED=0 ROUND_CAP=4 SLUG="" OUT="" PRINT=0
    25	while (($# > 0)); do
    26	  case "$1" in
    27	    --title) TITLE="${2:-}"; shift 2 ;;
    28	    --reviewer) REVIEWER="${2:-}"; shift 2 ;;
    29	    --producer) PRODUCER="${2:-}"; shift 2 ;;
    30	    --artifact-file) ARTIFACT="${2:-}"; shift 2 ;;
    31	    --embed) EMBED=1; shift ;;
    32	    --round-cap) ROUND_CAP="${2:-}"; shift 2 ;;
    33	    --slug) SLUG="${2:-}"; shift 2 ;;
    34	    --out) OUT="${2:-}"; shift 2 ;;
    35	    --print) PRINT=1; shift ;;
    36	    --help) sed -n '2,30p' "$0"; exit 0 ;;
    37	    *) die "unknown argument: $1" ;;
    38	  esac
    39	done
    40	[[ -n "$TITLE" ]]    || { die "--title is required"; }
    41	[[ -n "$REVIEWER" ]] || { die "--reviewer is required"; }
    42	(( EMBED == 0 )) || [[ -n "$ARTIFACT" ]] || die "--embed requires --artifact-file"
    43	# --embed reads the file now, so it must exist. Reference mode only records the path (the artifact
    44	# may not exist yet — relay-drive seeds it at turn time), so it is NOT required to exist at scaffold.
    45	(( EMBED == 0 )) || [[ -f "$ARTIFACT" ]] || die "artifact file not found (required for --embed): $ARTIFACT"
    46	
    47	# Fence longer than the longest backtick run inside <file>, min 3 (GH-31 Phase 3 — fence-collision safe).
    48	fence_for() {
    49	  local f="$1" longest=0
    50	  longest="$(grep -oE '`+' "$f" 2>/dev/null | awk '{ if (length>m) m=length } END { print m+0 }' || true)"
    51	  [[ -n "$longest" ]] || longest=0
    52	  local n=$((longest + 1)); (( n < 3 )) && n=3
    53	  printf '%*s' "$n" '' | tr ' ' '`'
    54	}
    55	
    56	slugify() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//'; }
    57	[[ -n "$SLUG" ]] || SLUG="$(slugify "$TITLE")"
    58	TODAY="$(date +%F)"
    59	
    60	art_base=""; [[ -n "$ARTIFACT" ]] && art_base="$(basename "$ARTIFACT")"
    61	
    62	emit() {
    63	  cat <<EOF
    64	# RELAY · $TITLE
    65	<!--
    66	  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
    67	  Scaffolded by relay-automation/new-relay.sh on $TODAY.
    68	-->
    69	
    70	NEXT: Reviewer
    71	STATUS: Open
    72	ROUND: 1 / $ROUND_CAP
    73	
    74	## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
    75	1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
    76	2. **Check it's your turn:** \`NEXT\` (top) names the role to act. Confirm you are bound to it and the
    77	   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
    78	3. **Do your role's work** on the artifact named in Setup:
    79	   - **Reviewer:** review vs the Definition of Done → graded findings
    80	     (\`[Blocker]\`/\`[Should]\`/\`[Nit]\`/\`[Pass]\`), each with a concrete fix → set a **VERDICT**
    81	     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
    82	     a beta test had this loop reach \`Approved\` in two rounds while an independent audit of the same
    83	     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
    84	     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
    85	     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
    86	     **Declare it: every review block must contain a literal \`swept file: yes\` or \`swept file: no\`
    87	     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
    88	     one that did it and found nothing — which is how the original 20 issues stayed invisible.
    89	     Any \`[Pass]\` or "verified"/"confirmed" finding MUST
    90	     carry a quoted span or a \`file:line\` citation — an uncited one is mechanically downgraded to
    91	     \`[Unverified — no citation]\` (GH-173 B3). Do **not** edit the artifact; only append findings here.
    92	   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
    93	     make the change, then add new work.
    94	4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
    95	5. **Update the header:** flip \`NEXT\`; set \`STATUS\` (\`Approved\` closes — Reviewer only; else \`Open\`);
    96	   the Producer bumps \`ROUND\` when opening a new cycle. If the max \`ROUND\` ends without \`Approved\`,
    97	   set \`STATUS: Escalated\`.
    98	6. **Commit only the relay file** (\`relay($SLUG): <role> r<N>\`); no push. **Stop** and report one line.
    99	7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   100	   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   101	   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   102	   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   103	   was merely waiting looked stalled. A turn that ends without this line is not finished.
   104	
   105	## Setup
   106	EOF
   107	
   108	  if (( EMBED )); then
   109	    local fence; fence="$(fence_for "$ARTIFACT")"
   110	    cat <<EOF
   111	- Artifact under review: **$art_base** (embedded below — read it here).
   112	- Reviewer: $REVIEWER   ·   Producer: $PRODUCER
   113	- Started: $TODAY
   114	
   115	### Artifact — $art_base
    18	## Components
    19	| Script | Role |
    20	|---|---|
    21	| `poll.sh` | **Phase 4** per-tick poll driver. Reads state, applies the guard, dispatches `runner.sh`/`watchdog.sh` or idles. Run under `/loop`. |
    22	| `relay-loop.sh` | **GH-33 Phase 2/3 + GH-46 Phase 4** adaptive-cadence wrapper over `poll.sh` (which stays a pure oracle). Default = one tick that prints `NEXT-POLL: <s>` for a `/loop` dynamic tick / cron / any scheduler; `--sleep-loop` self-paces in pure bash (no Claude dep). **`--background`** dispatches the turn DETACHED on `run-runner`, and on `nudge-cross-model` it dispatches `--cross-model-cmd` only when that command is configured and reachable; otherwise it prints the same manual nudge `poll.sh` would have emitted. A pidfile (`<relay-file>.bgpid` or `--bg-pidfile`) is still the single-turn lock (`BG-RUNNING`, no double-dispatch; stale pidfile cleared before the fresh decision acts). Containment is **inherited** — the backgrounded process is the same runner/shim boundary, so the `relay-turn-lib.sh` boundary is byte-identical (`&` changes only when the parent returns). |
    23	| `runner.sh` | **Phase 3** single agent/turn: claim → run (`--agent-cmd`) → verdict gate (`VERDICT: PASS\|FAIL\|PARKED`) → done/retry; artifact-scoped clean-tree gate. |
    24	| `watchdog.sh` | **Phase 2** liveness: `tick analyze --format json` → parked `parked_suspects[]` → structured escalation record; reap gated behind `--allow-reap` (stub, pending an authority decision). |
    25	| `relay-drive.sh` | **Phase 4b** relay supervisor: loops a `/relay` Producer↔Reviewer thread to termination via a turn-taker; round cap + no-progress escalation. |
    26	| `relay-turn-lib.sh` | **Shared safety core** (sourced, not run): the model-agnostic containment contract — path-allowlist + commit-bypass guard + no-push. Both headless turn-takers source this so the boundary lives in ONE place. See [decisions/2026-06-15-unattended-agent-containment.md](../decisions/2026-06-15-unattended-agent-containment.md). |
    27	| `claude-turn.sh` | Native Claude relay reviewer and explicitly selected builder; shared token and allowlist enforcement. |
    28	| `codex-turn.sh` | **Option-A** headless turn-taker for the **Codex** agent (`codex exec`); thin dispatch wrapper over `relay-turn-lib.sh`. |
    29	| `agy-turn.sh` | **Option-A** headless turn-taker for the **agy** (Antigravity CLI) agent (`agy -p`); thin dispatch wrapper over `relay-turn-lib.sh`. Permanent replacement for `gemini-turn.sh`; live-validated 2026-06-18. |
    30	| `pi-turn.sh` | **GH-295** headless turn-taker for **Pi** (`pi.dev`, package `@earendil-works/pi-coding-agent`; `pi --provider … --model … --mode json -p`); thin dispatch wrapper over `relay-turn-lib.sh`. Same posture as agy (no built-in sandbox — containment is worktree isolation + `rtl_enforce`), but genuinely better on cost visibility: `--mode json`'s JSONL stream carries real per-call `usage`/`cost` fields, so this is the first non-Claude lane with actual `tick cost --tool pi` capture. `PI_MODEL` has **no default** by design (GH-280/aider#5486 class of bug); the operator must set it explicitly. |
    31	| `aider-turn.sh` | Headless turn-taker for **Aider ↔ OpenRouter** (`aider --model openrouter/… --message`) — an OpenAI-standard lane discrete from Codex. Same `relay-turn-lib.sh` containment; because Aider is a file-editor (no mid-turn shell), the SHIM performs the tick token ops itself and runs Aider with `--no-auto-commits` (the harness owns the commit). Set `OPENROUTER_API_KEY` + `AIDER_MODEL` (e.g. `openrouter/anthropic/claude-3.5-sonnet`, `openrouter/openai/gpt-4o`, `openrouter/deepseek/deepseek-chat`). Works in **both** a marathon `--builder aider` lane AND a plain `/relay` — it routes through the shared `marathon-agent.sh` dispatcher (`relay-drive.sh`'s `--agent-cmd`), so a driven relay with `RELAY_AGENT=aider` fires it just like Codex/agy. |
    32	| `deep-research.mjs` | **Provider-agnostic grounded web search** (GH-87/GH-129): one normalized `{answer, citations, query, provider, model, raw}` contract over two backends — **Agy Gemini Search** (default; `agy` CLI in a throwaway tmpdir, side-effect free) and **Perplexity Sonar via OpenRouter** (`--provider openrouter`; same `OPENROUTER_API_KEY` gateway convention as the Aider lane, model `perplexity/sonar` overridable via `DEEP_RESEARCH_OPENROUTER_MODEL`, `--search-context-size` → Perplexity's native `web_search_options.search_context_size`). Fail-closed typed errors (`binary_missing`/`missing_api_key`/`timeout`/`backend_error`/`empty_output`) — never a silent cross-provider fallback. Run sandbox-OFF; prefer `--search-context-size medium` with focused single-intent queries (`high` risks runaway grounding near the 120s `DEEP_RESEARCH_TIMEOUT_MS` cap — see #124). Wall-clock cap is `DEEP_RESEARCH_TIMEOUT_MS`, default `120000` (120s); override upward (e.g. `DEEP_RESEARCH_TIMEOUT_MS=180000`) when a thorough `high`-context, multi-claim query genuinely needs more headroom — the default itself is unchanged. |
    33	| `xyz-vendor.sh` / `xyz-sync.sh` | Vendoring pair for `.xyz/` copies materialized into another repo. `xyz-vendor.sh <target-repo> [--with-releases]` mirrors this harness into `<target-repo>/.xyz/` (Tier 1 core harness by default; Tier 2 with RELEASES overlay via `--with-releases` or sticky auto-detection when `releases.db` is present at target root) and stamps a row in the local `registry.tsv` (`install_dir`, `last_install_utc`, `tick_version`, `source_commit`, `coordinated_repo`) at that moment. `xyz-sync.sh list \| update \| delete \| check` manages those registered rows: `list` shows them, `update <dir>\|--all` re-vendors, `delete <dir>\|--all [--yes]` removes a copy and prunes its row, `check <dir>\|--all` reports drift. |
    34	| `xyz-releases-onboard.sh` | **GH-197** onboarding SOP script to migrate a legacy `RELEASES.md` into the Tier 2 SQLite ledger (`releases.db` + `releases.sql`), auditing `.gitignore` for `!releases.db` carve-outs, prepending the app-managed banner, reconciling `MIG-` references to GitHub issue URLs with shared-tracking-URL collision detection, and running validation without auto-committing. |
    35	
    78	and exits with failure rather than silently deleting it.
    79	
    80	| Task | Existing XYZ route |
    81	|---|---|
    82	| One-shot consult | `consult.sh --models claude`, with `Read`, `Grep`, and `Glob` tools; no configured MCP tools |
    83	| Standalone relay review | `CLAUDE_AGENT=<reviewer-id>` with `relay-drive.sh --reviewer <reviewer-id> --agent-cmd relay-automation/claude-turn.sh` |
    84	| Explicit builder | `--builder claude` in Marathon, or the existing Claude relay adapter with the artifact allowlist |
    85	
    86	Load the relay skill before driving a relay. Relay reviewers still need to write their
    87	review block and hand off the tick token; the shared reviewer contract limits artifact
    88	changes. Marathon reviewers remain restricted to Codex/Agy. Default builders are unchanged.
    89	
    90	`CLAUDE_REASONING_EFFORT` optionally sends native `--effort` to both consult and relay:
    91	`low`, `medium`, `high`, `xhigh`, or `max`. Invalid values fail before dispatch; omission
    92	leaves the CLI default untouched and relay telemetry records `cli-default`. For example,
    93	set `CLAUDE_MODEL=opus CLAUDE_REASONING_EFFORT=high` for an Opus high-effort request.
    94	
   285	### Designated watchdog (exactly ONE window)
   286	Only one poller holds watchdog authority, so a stalled turn is escalated once
   287	without double-escalation:
   288	```
   289	/loop 120s run relay-automation/poll.sh --mode relay --agent coordinator \
   290	  --relay-file relay-system/<date>/<slug>.md --watchdog-authority ;\
   291	  if it prints "DECISION: run-watchdog", it has escalated the parked turn — surface it to me.
   292	```
   293	
   294	### Single-process relay supervision (one window drives the whole thread)
   295	```
   296	relay-automation/relay-drive.sh --relay-file relay-system/<date>/<slug>.md \
   297	  --agent-cmd "<turn-taker>" --reviewer <agent-id> [--builder <agent-id>] --round-cap 6
   298	```
   299	`--reviewer` names the ONE agent whose approval counts (GH-505/GH-509): the driver exports the
   300	role it dispatched per turn, pins the revision the reviewer reads, and attests a terminal
   301	`STATUS: Approved` only when it watched that agent's turn add review text — a terminal STATUS
   302	written by any other turn is reverted and escalated `forged-terminal`; a file that is already
   303	terminal at startup escalates `unattested-terminal`. Without `--reviewer` the driver warns and can
   304	never accept a terminal status. `--agent-cmd` is the turn-taker seam; a custom command must route
   305	`RELAY_AGENT` to a contained shim (as `marathon-agent.sh` does) — the token names *who*, the shim
   306	supplies *containment*, and only a turn whose shim returned 0 can be attested. In the live-window flow it can remain a
   307	window-driven/manual handoff; in the current headless path it can be a shipped
   308	shim such as `relay-automation/codex-turn.sh` or `relay-automation/agy-turn.sh`.
   309	Exits: `0` closed Approved/Closed, `3` no-progress, `4` round cap / closed-not-approved, `5`
   310	(with `--review-once`) reviewer completed a single non-approval review. Inspect whose-turn mid-drive
   311	with `tick info <task>` (the verb is `info`, not `status`).
   312	
   313	### Cross-model windows (Codex / agy)
   314	In the poll-based multi-window flow, non-Claude windows still need a wake-up path.
   315	Without `relay-loop.sh --background --cross-model-cmd <shim>`, the operator's
   390	exposes, e.g. `PI_MODEL=openai/gpt-mini-latest`; run `pi --list-models` to see
   391	your account's catalog. `PI_PROVIDER` defaults to `openrouter`, reusing this
   392	harness's existing `OPENROUTER_API_KEY` — no extra credential wiring needed for
   393	that default seam. `pi`'s built-in tools (`read`/`bash`/`edit`/`write`) run with
   394	no separate approval flag needed in headless `-p` mode (unlike Codex, there is
   395	no interactive approval gate to disable). If `pi` is not on `PATH`, fix that
   396	before running the shim, or override the binary with `PI_BIN=/path/to/pi`.
   397	
   398	If you are running under a sandboxed AI shell, run all three workers outside
   399	that sandbox. Codex often fails there because it cannot reach the OS keychain
   400	or `chatgpt.com`; agy can fail "cleanly" with empty output when its backend
   401	network is blocked; Pi's containment posture is the same as agy's (no
   402	built-in sandbox of its own — see the Pi worker subsection below).
   403	
   404	### 2. Clone or refresh the harness
   405	
   406	```bash
   407	git clone https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm.git
   408	cd xyz-3-agents-swarm
   409	# or, in an existing clone: git pull origin main
   410	export TICK_REPO_ROOT="$PWD"
nl: decisions/2026-06-15-unattended-agent-containment.md: No such file or directory
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
    72	
    73	# `check --rebuild` displaces the old DB to this path, and utils/releases-merge-resolve.sh tells the
    74	# operator it is "untracked and safe to delete". It was not actually ignored, so a `git add -A`
    75	# during a merge resolution would have committed a ~200KB stale binary copy of the ledger — the one
    76	# artifact guaranteed to disagree with the dump (GH-57 probe, 2026-08-19).
    77	releases.db.bak
    78	
    79	# GH-549: the connector dispatch mutex, beside the ledger it guards. Same reasoning as the
    80	# agent2agent locks below — a flock file is per-machine runtime state, never repo content, and
    81	# it must not be unlinked (unlinking a flock file is what reintroduces the steal race).
    82	releases.db-connectors.lock
    83	
    84	# GH-38: agent2agent lock files are flock mutexes, deliberately never unlinked (unlinking is what
    85	# reintroduced the steal race). They are per-machine runtime state, never discussion content.
    86	relay-system/**/.*.lock
    87	# Doorbell liveness markers — per-agent, mtime-only, regenerated by every watch.
    88	relay-system/**/*.watch.agent*
    89	# GH-236 QA / GH-327: agent-chorus USED to root its telemetry sidecar at <discussion>/runtime for
    90	# any discussion path, so a join/send/close against a legacy relay-system discussion wrote
    91	# telemetry.jsonl and close_report.json into the worktree — unreachable by `telemetry purge`, which
    92	# only walks the store. Fixed at the source: telemetry_runtime_dir() now returns None for anything
    93	# not named conversation.md, so no such file is written any more.
    94	#
    95	# Kept anyway, deliberately. It costs nothing, and it is the backstop if a future call site
    96	# re-derives a runtime path by hand instead of going through the resolver — which is exactly the
    97	# mistake close_report.json had already made once.
    98	relay-system/**/runtime/
    99	
   100	# Audit probe output when --out is pointed at the worktree (default is a scratch dir).
   101	audit/out/
   102	.relay-scratch/
   103	
   104	# SQLite side files. Opening either ledger DB with the sqlite3 CLI creates a -wal/-shm pair;
   105	# they are transient (checkpoint them into the .db before committing) and must never be tracked —
   106	# a committed -wal makes the .db bytes an incomplete picture of the ledger.
   107	*.db-wal
   108	*.db-shm
   109	
   110	# GH-299 Gen 4: mutational fuzz corpus — per-machine, regenerable from --seed, never committed.
   111	.fuzz_corpus/
   112	
   113	# browserbase skill: local env files must never be tracked (key lives in ~/secrets/)
   114	skills/browserbase/.env*

exec
/bin/zsh -lc "rg --files | rg 'unattended-agent-containment|new-relay|relay-turn-lib|codex-turn|agy-turn|pi-turn|claude-turn'
nl -ba relay-automation/relay-turn-lib.sh | sed -n '862,975p'
nl -ba relay-automation/relay-turn-lib.sh | sed -n '1128,1182p'
nl -ba relay-automation/relay-turn-lib.sh | sed -n '1320,1402p'
nl -ba relay-automation/new-relay.sh | sed -n '18,105p'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-93733-mu26k550
 succeeded in 0ms:
relay-automation/pi-turn.sh
relay-automation/new-relay.sh
relay-automation/relay-turn-lib.sh
relay-automation/claude-turn.sh
relay-automation/codex-turn.sh
relay-automation/agy-turn.sh
utils/py/claude-turn.py
utils/py/codex-turn.py
utils/py/agy-turn.py
utils/py/pi-turn.py
test/agy-turn.sh
test/codex-turn.sh
test/claude-turn.sh
test/new-relay.sh
test/pi-turn.sh
evidence/marathons/run-1/artefacts/run-logs/2026-08-20/claude-turn-MARATHON-R3P1-TURN-22215.log
evidence/marathons/run-2/artefacts/run-logs/2026-08-20/claude-turn-MARATHON-R3P1-TURN-22215.log
   862	rtl_worktree_end() {  # [<wt>] — sets RTL_WT_OFFLANE (0|1); copies allowlist back unless off-lane found
   863	  # Contain + DETECT: if the agent touched anything outside {allowlist, .tick} in the worktree, that's
   864	  # an off-lane attempt — do NOT copy anything back (the turn must fail like an in-ROOT exit-6), set
   865	  # RTL_WT_OFFLANE=1, and destroy the worktree. Otherwise copy ONLY the allowlist back to RTL_ROOT —
   866	  # edits/creates propagate, AND an allowlisted path the turn DELETED in the worktree is removed from
   867	  # RTL_ROOT too (so an isolated Producer that deletes an artifact isn't silently undone — Codex review
   868	  # 2026-06-20) — then destroy the worktree.
   869	  local wt="${1:-${RTL_WT:-}}" a entry xy path
   870	  RTL_WT_OFFLANE=0
   871	  [[ -n "$wt" && -d "$wt" ]] || return 0
   872	  rtl_trace "rtl_worktree_end: WT=$wt"
   873	  # GH-266: the harness's own transcript-log directory, when NOT redirected via XYZ_ARCHIVE_ROOT (the
   874	  # default), lives inside RTL_ROOT itself and is genuinely new/untracked in a fresh isolated worktree
   875	  # — exempt it the same way .tick/ is exempted below, mirroring rtl_check()'s $RTL_LOG_REL exemption
   876	  # (line ~683). When XYZ_ARCHIVE_ROOT IS set, rtl_transcript_root resolves outside RTL_ROOT entirely,
   877	  # so nothing here would ever appear in this worktree's own git status — no exemption needed then.
   878	  local _rtl_log_top=""
   879	  [[ -z "${XYZ_ARCHIVE_ROOT:-}" ]] && _rtl_log_top="$(basename "$(rtl_transcript_root "$RTL_ROOT")")"
   880	  # GH-13/#14: rtl_worktree_begin runs in a `wt="$(...)"` subshell, so the RTL_WT_USED=1 it sets there
   881	  # is LOST before rtl_enforce runs — which left the "a moved ROOT HEAD is a concurrent PEER commit;
   882	  # preserve it, don't reset" branch in rtl_enforce as DEAD CODE for the command-substitution shims
   883	  # (codex/agy). Every moved ROOT HEAD then wrongly hit the in-ROOT reset+exit-6 path, discarding a
   884	  # worktree builder's whole turn (the 2026-06-29 codex marathon, #14). This function runs in the
   885	  # caller's shell and is always reached before rtl_enforce for a worktree turn, so re-assert the flag
   886	  # here to restore the GH-13 protection. (The agent ran CWD=worktree, so its OWN commits can't reach
   887	  # ROOT; a moved ROOT HEAD is genuinely a peer/harness commit. Off-lane worktree content is already
   888	  # contained below before rtl_enforce sees it.)
   889	  RTL_WT_USED=1
   890	  while IFS= read -r -d '' entry; do
   891	    [[ -n "$entry" ]] || continue
   892	    xy="${entry:0:2}"; path="${entry:3}"
   893	    case "$xy" in R*|C*) IFS= read -r -d '' _ || true ;; esac   # rename/copy: consume 2nd NUL field
   894	    case "$path" in .tick/*|.tick) continue ;; esac
   895	    # GH-91: builder scratch / verification output — sanctioned, writable by design, exempt with
   896	    # NO signature check (unlike .relay-artifacts above: scratch is meant to be written), never
   897	    # copied back (the copyback loop iterates RTL_ALLOW only), discarded with the worktree.
   898	    case "$path" in .relay-scratch|.relay-scratch/|.relay-scratch/*) continue ;; esac
   899	    # GH-266: git collapses an all-untracked dir to one line (same reasoning as .relay-artifacts
   900	    # below) — match both the bare transcript-log directory name and any path under it.
   901	    if [[ -n "$_rtl_log_top" ]]; then
   902	      case "$path" in "$_rtl_log_top"|"$_rtl_log_top"/|"$_rtl_log_top"/*) continue ;; esac
   903	    fi
   904	    # GH-31 / #15: the read-only artifact seed. Exempt ONLY while unchanged from the seed; a reviewer
   905	    # edit changes the .relay-artifacts dir signature → strict-fail as off-lane (read-only enforced,
   906	    # not silently discarded). git collapses an all-untracked dir to ".relay-artifacts/", so match both.
   907	    case "$path" in
   908	      .relay-artifacts|.relay-artifacts/|.relay-artifacts/*)
   909	        if [[ -f "${wt}.artifactsig" ]] && [[ "$(_rtl_sig "$wt/.relay-artifacts")" == "$(cat "${wt}.artifactsig")" ]]; then
   910	          continue
   911	        fi
   912	        rtl_trace "rtl_worktree_end: OFFLANE path=$path (artifact modified)"
   913	        RTL_WT_OFFLANE=1; continue ;;
   914	    esac
   915	    rtl_in_allow "$path" && continue
   916	    rtl_is_containment_ignored "$path" && continue   # GH-107: opt-in tool-cache exemption
   917	    # GH-113: same scratch relocation as rtl_check's non-worktree path — a scratch-shaped untracked
   918	    # root file in the throwaway worktree is moved into RTL_ROOT's .tick/scratch for inspection
   919	    # (the worktree itself is destroyed below, which would otherwise destroy the evidence) and the
   920	    # turn is NOT failed on it.
   921	    rtl_scratch_relocate "$path" "$wt" "$RTL_ROOT" && continue
   922	    rtl_offlane_hint "$path"                         # GH-90: name a file-vs-directory lane-spec mistake
   923	    rtl_trace "rtl_worktree_end: OFFLANE path=$path"
   924	    RTL_WT_OFFLANE=1                    # a non-allowlist, non-.tick change → off-lane
   925	  done < <(git -C "$wt" status --porcelain -z 2>/dev/null)
   926	  rtl_trace "rtl_worktree_end: OFFLANE_VERDICT=$RTL_WT_OFFLANE"
   927	  if ((RTL_WT_OFFLANE == 0)); then
   928	    local i=0 seedsig nowsig _ln; local _seeds=()
   929	    # Re-read the seed signatures written by rtl_worktree_begin (one line per RTL_ALLOW entry).
   930	    if [[ -f "${wt}.seedsig" ]]; then
   931	      while IFS= read -r _ln; do _seeds+=("$_ln"); done <"${wt}.seedsig"
   932	    fi
   933	    for a in "${RTL_ALLOW[@]}"; do
   934	      # GH-30 Phase 3: skip the absolute archive relay-file entry — never seeded here (committed to the
   935	      # archive by rtl_enforce). Skipped in lockstep with the begin seedsig loop, so `i` stays aligned.
   936	      [[ "$a" == /* ]] && continue
   937	      # GH-22: copy back ONLY paths the turn changed IN THE WORKTREE. If the worktree path is identical
   938	      # to what was seeded, the turn did not touch it here — leave RTL_ROOT alone so a ROOT-direct edit
   939	      # (agy writing the absolute ROOT path) survives for rtl_enforce to commit, instead of being
   940	      # overwritten by the stale seed. No recorded seed signature → copy as before (safe fallback).
   941	      seedsig="${_seeds[i]-}"; i=$((i+1))
   942	      nowsig="$(_rtl_sig "$wt/$a")"
   943	      if [[ -n "$seedsig" && "$nowsig" == "$seedsig" ]]; then
   944	        rtl_trace "rtl_worktree_end: UNCHANGED $a (left ROOT alone)"
   945	        continue
   946	      fi
   947	      if [[ -e "$wt/$a" ]]; then
   948	        mkdir -p "$RTL_ROOT/$(dirname "$a")"
   949	        # GH-140: copy into a temp path beside the destination, then atomically rename it into place —
   950	        # NOT a direct in-place `cp -R` onto $RTL_ROOT/$a. A plain cp truncates+rewrites an existing
   951	        # destination at the SAME inode; if $a is a script actively being interpreted right now (this
   952	        # very marathon-drive.sh, or its relay-drive.sh subprocess — both are legitimate copyback
   953	        # targets for a Seam #1-style lane), the live reader can observe a half-old/half-new file mid
   954	        # execution. A 2026-07-05 run hit exactly this: the outer process crashed with a garbled parse
   955	        # immediately after copyback, then corrupted further into wiping the working tree. `mv` on the
   956	        # same filesystem is an atomic rename (same pattern as append-xyz-completion.sh's os.replace) —
   957	        # an fd already open on the old $RTL_ROOT/$a keeps reading the old inode until it closes, and it
   958	        # never observes a nonexistent or half-written path in between.
   959	        local _tmp="$RTL_ROOT/$(dirname "$a")/.rtl-copyback.$$.$(basename "$a")"
   960	        rm -rf "$_tmp"
   961	        cp -R "$wt/$a" "$_tmp"
   962	        if [[ -d "$_tmp" && ! -L "$_tmp" ]]; then
   963	          # rename(2) cannot atomically replace a non-empty directory — remove the old one first.
   964	          # No live process reads a directory as an executing script, so this narrow window is safe.
   965	          rm -rf "$RTL_ROOT/$a"
   966	          mv "$_tmp" "$RTL_ROOT/$a"
   967	        else
   968	          # Regular file (or symlink): rename(2) atomically clobbers an existing destination directly —
   969	          # no separate rm, no window where the path is missing.
   970	          mv -f "$_tmp" "$RTL_ROOT/$a"
   971	        fi
   972	        rtl_trace "rtl_worktree_end: COPIED $a"
   973	      elif [[ -e "$RTL_ROOT/$a" ]]; then
   974	        rm -rf "$RTL_ROOT/$a"            # allowlisted path deleted in the worktree → propagate the deletion
   975	        rtl_trace "rtl_worktree_end: DELETED $a (removed from ROOT)"
  1128	  case "$p" in ""|.|..|*/*|.*) return 1 ;; esac
  1129	  [[ "$p" =~ ^(tmp|temp|scratch|debug|test_|fix_|repro_|probe_) ]] \
  1130	    || [[ "$p" =~ \.(tmp|temp|bak|orig)$ ]] \
  1131	    || [[ "$p" == *~ ]] \
  1132	    || return 1
  1133	  git -C "$src_root" ls-files --error-unmatch -- "$p" >/dev/null 2>&1 && return 1
  1134	  [[ -e "$src_root/$p" ]] || return 1
  1135	  dest="${RTL_SCRATCH_DIR:="${dest_root:?}/.tick/scratch/$(date -u +%Y%m%dT%H%M%SZ)-$$"}"
  1136	  mkdir -p "$dest" 2>/dev/null || return 1
  1137	  mv "$src_root/$p" "$dest/$p" 2>/dev/null || return 1
  1138	  printf '%s-turn: SCRATCH RELOCATION (GH-113): untracked root-level %s moved to %s — turn NOT failed. Write scratch under $TMPDIR or .relay-scratch/ instead.\n' \
  1139	    "${RTL_TOOL:-relay}" "$p" "$dest" >&2
  1140	  rtl_log_always "rtl_scratch_relocate: path=$p src=$src_root dest=$dest (GH-113)"
  1141	  return 0
  1142	}
  1143	
  1144	rtl_check() {  # <path> — reads RTL_ROOT/RTL_LOG_REL/RTL_TOOL, sets RTL_VIOLATION
  1145	  local p="$1"
  1146	  [[ -n "$p" ]] || return 0
  1147	  # tick's own state dir is coordination state the turn legitimately writes — exempt it intrinsically,
  1148	  # independent of whether the HOST repo gitignores .tick (field report MBP16 [2]).
  1149	  case "$p" in .tick/*|.tick) return 0 ;; esac
  1150	  # GH-91: same sanction on the non-worktree path, but here the dir lives in RTL_ROOT itself —
  1151	  # exempt AND discard (the transcript-log drop below is the precedent, not the .tick leave-in):
  1152	  # scratch is consumed by the turn that wrote it and must neither ride into a commit nor linger
  1153	  # in the tree. ${RTL_ROOT:?} because rm -rf on an empty-prefix path would target /. — GH-567.
  1154	  case "$p" in .relay-scratch|.relay-scratch/|.relay-scratch/*)
  1155	    rm -rf "${RTL_ROOT:?}/.relay-scratch"
  1156	    return 0
  1157	  ;; esac
  1158	  # the shim's own transcript log, if it lands in the tree, is not an agent edit — drop it, don't flag
  1159	  if [[ -n "$RTL_LOG_REL" && "$p" == "$RTL_LOG_REL" ]]; then rm -f "$RTL_ROOT/$p"; return 0; fi
  1160	  # GH-261: the exact-match exemption above only fires for the ONE transcript file itself; when the
  1161	  # harness's own transcript-log directory is entirely new/untracked, git collapses it to one line
  1162	  # (e.g. "relay-system/"), which never equals $RTL_LOG_REL's deeper file path. Mirrors
  1163	  # rtl_worktree_end's GH-266 fix, applied here to the non-worktree containment path too.
  1164	  if [[ -z "${XYZ_ARCHIVE_ROOT:-}" ]]; then
  1165	    local _rtl_log_top; _rtl_log_top="$(basename "$(rtl_transcript_root "$RTL_ROOT")")"
  1166	    case "$p" in "$_rtl_log_top"|"$_rtl_log_top"/|"$_rtl_log_top"/*) return 0 ;; esac
  1167	  fi
  1168	  if rtl_in_allow "$p"; then
  1169	    rtl_trace "rtl_check: ALLOW path=$p"
  1170	    return 0
  1171	  fi
  1172	  # GH-113: scratch-shaped untracked root files relocate instead of violating — AFTER the allowlist
  1173	  # check so an explicitly allowlisted path keeps its normal handling, and BEFORE the revert so the
  1174	  # turn is not failed on transient scratch.
  1175	  rtl_scratch_relocate "$p" "$RTL_ROOT" && return 0
  1176	  printf '%s-turn: OFF-ALLOWLIST change: %s — reverting\n' "$RTL_TOOL" "$p" >&2
  1177	  rtl_log_always "rtl_check: OFF-ALLOWLIST path=$p tool=$RTL_TOOL — reverting"
  1178	  rtl_offlane_hint "$p"    # GH-90: name a file-vs-directory lane-spec mistake before the revert
  1179	  rtl_orphan_backup "$p"   # GH-141: recoverable copy BEFORE the destructive revert below
  1180	  git -C "$RTL_ROOT" checkout -- "$p" 2>/dev/null || rm -rf "$RTL_ROOT/${p%/}"
  1181	  RTL_VIOLATION=1
  1182	}
  1320	      }
  1321	    }
  1322	  ' "$prompt" "$transcript"
  1323	}
  1324	
  1325	rtl_enforce() {  # <task> <agent> <log> <tool>
  1326	  local task="$1" agent="$2" log="$3"; RTL_TOOL="$4"
  1327	  # (2) commit-bypass guard: the agent must NOT git. If HEAD moved, its edits are hidden from
  1328	  # `git status` — undo the commit(s) and fail, so off-lane changes can't slip in committed.
  1329	  if [[ "$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)" != "$RTL_BEFORE_HEAD" ]]; then
  1330	    if [[ "${RTL_WT_USED:-0}" == "1" ]]; then
  1331	      # GH-13: this turn ran in a throwaway worktree, so the agent CANNOT have moved ROOT's HEAD — a
  1332	      # moved ROOT HEAD is therefore a CONCURRENT PEER commit. Never reset it: a blind `reset --hard`
  1333	      # here orphaned a peer agent's commit on 2026-06-23 (recovered via reflog). The agent's own writes
  1334	      # were already contained by rtl_worktree_end (off-lane → exit 6; else allowlist copyback), so just
  1335	      # preserve the peer commit and fall through to allowlist enforcement + a file-scoped commit ON TOP.
  1336	      printf '%s-turn: ROOT HEAD moved during a worktree-isolated turn — a concurrent peer committed; preserving it (not resetting), committing this turn on top.\n' "$RTL_TOOL" >&2
  1337	      rtl_log_always "rtl_enforce: HEAD_MOVED branch=peer-preserve (worktree-isolated; concurrent peer commit kept)"
  1338	    else
  1339	      # In-ROOT (direct/attended) turn: the agent ran in ROOT and may have committed off-lane changes.
  1340	      # Undo its commit and fail — the documented attended-mode containment. A concurrent PEER commit in
  1341	      # this mode is indistinguishable from a self-commit here, so before discarding it we save the
  1342	      # current HEAD under refs/relay-orphan/<sha>: the reset abandons it from the branch, but the ref
  1343	      # keeps it reachable, so a wrongly-caught peer commit is never lost (recover via
  1344	      # `git log refs/relay-orphan/*`). The default DRIVEN path uses worktree isolation (handled above);
  1345	      # this is the cheap backstop for the in-ROOT path (GH-13, relay review 2026-06-23 F6).
  1346	      git -C "$RTL_ROOT" update-ref "refs/relay-orphan/$(git -C "$RTL_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)" HEAD 2>/dev/null || true
  1347	      git -C "$RTL_ROOT" reset --hard "$RTL_BEFORE_HEAD" >/dev/null 2>&1 || true
  1348	      printf '%s-turn: %s committed during its turn (forbidden) — reset to %s (prior HEAD saved to refs/relay-orphan/), failing\n' "$RTL_TOOL" "$agent" "${RTL_BEFORE_HEAD:0:8}" >&2
  1349	      rtl_log_always "rtl_enforce: HEAD_MOVED branch=in-root-reset agent=$agent reset_to=${RTL_BEFORE_HEAD:0:8}"
  1350	      exit 6
  1351	    fi
  1352	  fi
  1353	  # (1) allowlist enforcement on tracked-tree changes (.tick is gitignored, so token ops don't show).
  1354	  # -z = NUL-delimited RAW unquoted paths (spaces/special chars can't slip the match or break the
  1355	  # revert); rename/copy records (R/C) carry a second NUL field — check both old+new. We deliberately
  1356	  # do NOT `git clean -Xdf` (it would wipe .tick, the coordination state the turn legitimately writes);
  1357	  # ignored-file safety belongs to the agent sandbox, tracked as future.
  1358	  RTL_LOG_REL="${log:+${log#"$RTL_ROOT"/}}"
  1359	  RTL_VIOLATION=0
  1360	  # Pre-existing ambient WIP (same status+path as before the turn) is left untouched, never failed.
  1361	  # (Documented minor gap: a file already dirty that the agent edits further to the SAME status code
  1362	  # isn't caught — acceptable for review turns.)
  1363	  local entry xy path src
  1364	  while IFS= read -r -d '' entry; do
  1365	    [[ -n "$entry" ]] || continue
  1366	    xy="${entry:0:2}"; path="${entry:3}"
  1367	    case "$xy" in
  1368	      R*|C*)
  1369	        IFS= read -r -d '' src || true
  1370	        # A rename counts as pre-existing only if BOTH dest and src were dirty before — else enforce
  1371	        # both paths. Prevents a staged rename whose dest matches an ambient rename's dest from hiding
  1372	        # a clean file's move/deletion via the src field (Gemini review 2026-06-15, rename-hijack).
  1373	        if rtl_was_dirty_before "$entry" && rtl_was_dirty_before "$src"; then continue; fi
  1374	        rtl_check "$path"; rtl_check "$src"
  1375	        ;;
  1376	      *)
  1377	        rtl_was_dirty_before "$entry" && continue
  1378	        rtl_check "$path"
  1379	        ;;
  1380	    esac
  1381	  done < <(git -C "$RTL_ROOT" status --porcelain -z)
  1382	  # GH-91 (PR #93 review): scratch must not survive the turn EVEN WHEN the host repo gitignores
  1383	  # it — porcelain omits ignored paths, so the per-path rtl_check discard above never fires and
  1384	  # the dir lingered in ROOT forever. Sweep unconditionally, independent of git visibility.
  1385	  [[ -d "${RTL_ROOT:?}/.relay-scratch" ]] && rm -rf "${RTL_ROOT:?}/.relay-scratch"
  1386	  rtl_trace "rtl_enforce: RTL_VIOLATION=$RTL_VIOLATION"
  1387	  ((RTL_VIOLATION == 0)) || { printf '%s-turn: off-lane edits reverted; failing the turn\n' "$RTL_TOOL" >&2; rtl_log_always "rtl_enforce: VIOLATION off-lane edits reverted; failing the turn"; exit 6; }
  1388	  # GH-173 B3: downgrade any uncited [Pass]/verified Reviewer finding BEFORE staging, so the fix lands
  1389	  # in the SAME commit as the turn instead of needing a second one. Reviewer-only (Producer findings
  1390	  # aren't graded by this template); RTL_WAS_REVIEWER_TURN was captured in rtl_init, before NEXT flipped.
  1391	  if [[ "${RTL_WAS_REVIEWER_TURN:-0}" == "1" && -n "${RELAY_FILE:-}" ]]; then
  1392	    rtl_check_uncited_findings "$RELAY_FILE"
  1393	    rtl_trace "rtl_enforce: checked $RELAY_FILE for uncited [Pass]/verified findings"
  1394	  fi
  1395	  # GH-410 / GH-21 / AGENTS.md §12: structural relay-block validation before staging.
  1396	  # The Reviewer turn must append a structurally valid review block (STATUS not In Progress,
  1397	  # ## Log present, VERDICT, and Basis).
  1398	  # If validation fails, exit 8 (relay block structural validation failed) so the harness
  1399	  # escalates rather than staging/committing a malformed block or handing off an invalid turn.
  1400	  if [[ "${RTL_WAS_REVIEWER_TURN:-0}" == "1" && -n "${RELAY_FILE:-}" ]]; then
  1401	    local _val_rf="${RELAY_FILE:-}" _val_tickroot="${TICK_REPO_ROOT:-${RTL_ROOT:-}}"
  1402	    if [[ "$_val_rf" != /* && ! -f "$_val_rf" ]]; then
    18	#       [--producer AGENT] [--round-cap N] [--slug S] [--out PATH | --print]
    19	#
    20	# Exit: 0 ok · 2 usage.
    21	
    22	die() { printf 'new-relay: %s\n' "$*" >&2; exit 2; }
    23	
    24	TITLE="" REVIEWER="" PRODUCER="claude-a" ARTIFACT="" EMBED=0 ROUND_CAP=4 SLUG="" OUT="" PRINT=0
    25	while (($# > 0)); do
    26	  case "$1" in
    27	    --title) TITLE="${2:-}"; shift 2 ;;
    28	    --reviewer) REVIEWER="${2:-}"; shift 2 ;;
    29	    --producer) PRODUCER="${2:-}"; shift 2 ;;
    30	    --artifact-file) ARTIFACT="${2:-}"; shift 2 ;;
    31	    --embed) EMBED=1; shift ;;
    32	    --round-cap) ROUND_CAP="${2:-}"; shift 2 ;;
    33	    --slug) SLUG="${2:-}"; shift 2 ;;
    34	    --out) OUT="${2:-}"; shift 2 ;;
    35	    --print) PRINT=1; shift ;;
    36	    --help) sed -n '2,30p' "$0"; exit 0 ;;
    37	    *) die "unknown argument: $1" ;;
    38	  esac
    39	done
    40	[[ -n "$TITLE" ]]    || { die "--title is required"; }
    41	[[ -n "$REVIEWER" ]] || { die "--reviewer is required"; }
    42	(( EMBED == 0 )) || [[ -n "$ARTIFACT" ]] || die "--embed requires --artifact-file"
    43	# --embed reads the file now, so it must exist. Reference mode only records the path (the artifact
    44	# may not exist yet — relay-drive seeds it at turn time), so it is NOT required to exist at scaffold.
    45	(( EMBED == 0 )) || [[ -f "$ARTIFACT" ]] || die "artifact file not found (required for --embed): $ARTIFACT"
    46	
    47	# Fence longer than the longest backtick run inside <file>, min 3 (GH-31 Phase 3 — fence-collision safe).
    48	fence_for() {
    49	  local f="$1" longest=0
    50	  longest="$(grep -oE '`+' "$f" 2>/dev/null | awk '{ if (length>m) m=length } END { print m+0 }' || true)"
    51	  [[ -n "$longest" ]] || longest=0
    52	  local n=$((longest + 1)); (( n < 3 )) && n=3
    53	  printf '%*s' "$n" '' | tr ' ' '`'
    54	}
    55	
    56	slugify() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//'; }
    57	[[ -n "$SLUG" ]] || SLUG="$(slugify "$TITLE")"
    58	TODAY="$(date +%F)"
    59	
    60	art_base=""; [[ -n "$ARTIFACT" ]] && art_base="$(basename "$ARTIFACT")"
    61	
    62	emit() {
    63	  cat <<EOF
    64	# RELAY · $TITLE
    65	<!--
    66	  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
    67	  Scaffolded by relay-automation/new-relay.sh on $TODAY.
    68	-->
    69	
    70	NEXT: Reviewer
    71	STATUS: Open
    72	ROUND: 1 / $ROUND_CAP
    73	
    74	## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
    75	1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
    76	2. **Check it's your turn:** \`NEXT\` (top) names the role to act. Confirm you are bound to it and the
    77	   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
    78	3. **Do your role's work** on the artifact named in Setup:
    79	   - **Reviewer:** review vs the Definition of Done → graded findings
    80	     (\`[Blocker]\`/\`[Should]\`/\`[Nit]\`/\`[Pass]\`), each with a concrete fix → set a **VERDICT**
    81	     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
    82	     a beta test had this loop reach \`Approved\` in two rounds while an independent audit of the same
    83	     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
    84	     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
    85	     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
    86	     **Declare it: every review block must contain a literal \`swept file: yes\` or \`swept file: no\`
    87	     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
    88	     one that did it and found nothing — which is how the original 20 issues stayed invisible.
    89	     Any \`[Pass]\` or "verified"/"confirmed" finding MUST
    90	     carry a quoted span or a \`file:line\` citation — an uncited one is mechanically downgraded to
    91	     \`[Unverified — no citation]\` (GH-173 B3). Do **not** edit the artifact; only append findings here.
    92	   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
    93	     make the change, then add new work.
    94	4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
    95	5. **Update the header:** flip \`NEXT\`; set \`STATUS\` (\`Approved\` closes — Reviewer only; else \`Open\`);
    96	   the Producer bumps \`ROUND\` when opening a new cycle. If the max \`ROUND\` ends without \`Approved\`,
    97	   set \`STATUS: Escalated\`.
    98	6. **Commit only the relay file** (\`relay($SLUG): <role> r<N>\`); no push. **Stop** and report one line.
    99	7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   100	   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   101	   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   102	   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   103	   was merely waiting looked stalled. A turn that ends without this line is not finished.
   104	
   105	## Setup

exec
/bin/zsh -lc "find . -path '*/decisions/*' -maxdepth 5 -type f | sort | sed -n '1,200p'
rg -n \"unattended agent containment|unattended-agent|path-allowlist|GH-91|GH-173 B3|swept file\" . --glob '*.md' --glob '*.sh' --glob '*.py'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-93733-mu26k550
 succeeded in 75ms:
./relay-system/2026-09-13/workhorse-mantra-triage-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-13/workhorse-mantra-triage-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-13/workhorse-mantra-triage-qa.md:67:swept file: no
./relay-system/2026-09-13/workhorse-mantra-triage-qa.md:93:swept file: yes
./relay-system/2026-09-13/workhorse-mantra-triage-qa.md:132:swept file: yes
./relay-system/2026-09-13/workhorse-mantra-triage-qa.md:165:swept file: yes
./relay-system/2026-09-06/gh457-model-aliasing-improvements.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-06/gh457-model-aliasing-improvements.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-06/gh457-model-aliasing-improvements.md:65:  adjustment text where one is warranted (or "no change" where none is), a `swept file:` line,
./relay-system/2026-09-06/gh457-model-aliasing-improvements.md:81:swept file: no
./relay-system/2026-09-06/gh457-model-aliasing-improvements.md:106:swept file: yes
./PROJECT/2-WORKING/GH-505-RELAY-REVIEWER-INTEGRITY.md:192:| canonical = header keys normalised | also applies the harness's own uncited-claim downgrade (GH-173 B3) | the shim rewrites pre-existing lines in place after a reviewer turn; without this port every real reviewer turn read as `review-body-rewritten` (`gh280` chain) |
./relay-system/2026-08-27/gh275-writeops-081831/gh275-writeops.codex.md:2270:   745	  # GH-91: the sanctioned scratch dir. The harness REQUIRES the builder to verify its work by
./relay-system/2026-08-27/gh275-writeops-081831/gh275-writeops.codex.md:2314:   789	    # GH-91: builder scratch / verification output — sanctioned, writable by design, exempt with
./relay-system/2026-09-13/gh589-mvp-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-13/gh589-mvp-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-13/gh589-mvp-qa.md:61:swept file: yes
./relay-system/2026-09-13/gh589-mvp-qa.md:87:swept file: yes
./relay-system/2026-09-13/pr599-agy-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-13/pr599-agy-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-13/pr599-agy-qa.md:61:**swept file: yes**
./relay-system/2026-09-13/pr599-agy-qa.md:85:**swept file: yes**
./relay-system/2026-09-13/gh605-plan-deepseek.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-13/gh605-plan-deepseek.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-13/gh605-plan-deepseek.md:56:Plan-only review. No production edits and NO validate.sh/test/*.sh execution in this linked worktree. Only this relay file is writable. Answer concretely with graded findings and exact VERDICT: PASS, FAIL or PARKED plus swept file: yes/no. Preserve earlier content. The driver owns all git operations; NEVER commit/amend/push despite generic scaffold instructions. Use the runtime-provided absolute tick command. On approval set STATUS Approved and mark the exact runtime token done; otherwise hand back to codex-author. No model substitution: this run is DeepSeek V4.1 Flash via OpenRouter.
./marathon-system/nightwatch-wave-1-2026-08-10--gh358-lock-flake-instrumentation/RELAY.md:158:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: test/xyz-completion.sh,utils/telemetry/append-xyz-completion.sh,test/gh358-lock-instrumentation.sh,validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./marathon-system/nightwatch-wave-1-2026-08-10--gh358-lock-flake-instrumentation/RELAY.md:193:swept file: yes
./relay-system/2026-09-13/gh606-plan.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-13/gh606-plan.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-13/gh606-plan.md:68:swept file: yes
./relay-system/2026-08-18/merge-order-230056/merge-order.codex.md:2382: - **GH-173 B3 + GH-178 A1/A4 — three bounded patches, one PR** 🆕 **2026-07-08, [PR #184](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/184)** — **B3**: found the actual uncited-"[Pass]" source is `new-relay.sh`'s scaffolded Reviewer template (not `consult.sh`'s PREAMBLE or `relay-turn-lib.sh`'s generic role_note); added a citation requirement there + a mechanical `rtl_check_uncited_findings()` downgrade in `relay-turn-lib.sh`. **A1**: `consult.sh`'s advisor `case` dispatch is now a data table (`ADV_NAMES`/`ADV_RUNFNS`); "add vendor N+1" recipe in `relay-automation/README.md`. **A4** (deliberately scoped down, not the full firsthand-vs-asserted taxonomy): reused A2's stdout+transcript+sidecar mechanism to stamp `NO FIRSTHAND VERIFICATION CITED` on any advisor answer with zero citations anywhere. All three carry regression tests; targeted suites green. See CHANGELOG `[Unreleased]` and both PDDA docs' Validation tables. → [GH-173-JEDI-WRIGHT-FEEDBACK.md](PROJECT/2-WORKING/GH-173-JEDI-WRIGHT-FEEDBACK.md) · [GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md](PROJECT/2-WORKING/GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md) · [#173](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/173) · [#178](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/178)
./relay-system/2026-08-18/push-volume-plan-review-ci-route-sh-docs-only-pattern.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-08-18/push-volume-plan-review-ci-route-sh-docs-only-pattern.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-08-18/push-volume-plan-review-ci-route-sh-docs-only-pattern.md:60:- swept file: yes
./relay-system/2026-08-18/push-volume-plan-review-ci-route-sh-docs-only-pattern.md:71:- swept file: yes
./relay-system/2026-08-18/push-volume-plan-review-ci-route-sh-docs-only-pattern.md:80:- swept file: yes
./relay-system/2026-08-18/gh32-releases-app-prd-review.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-08-18/gh32-releases-app-prd-review.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-08-18/gh32-releases-app-prd-review.md:65:swept file: yes
./relay-system/2026-08-18/gh32-releases-app-prd-review.md:139:swept file: yes
./relay-system/2026-08-18/gh32-releases-app-prd-review.md:187:swept file: yes
./relay-system/2026-08-18/gh32-releases-app-prd-review.md:256:swept file: yes
./relay-system/2026-08-18/gh32-releases-app-prd-review.md:298:swept file: yes
./relay-system/2026-08-18/gh32-releases-app-prd-review.md:372:swept file: yes
./relay-system/2026-08-18/gh32-releases-app-prd-review.md:416:swept file: yes
./relay-system/2026-08-18/gh32-releases-app-prd-review.md:475:swept file: yes
./marathon-system/2026-09-01-xyz-harness-quickwins--p2-turn-supervision/RELAY.md:86:swept file: yes
./marathon-system/2026-09-01-xyz-harness-quickwins--p2-turn-supervision/RELAY.md:100:   - `relay-automation/relay-turn-lib.sh`: swept file: yes (critical race condition found in `rtl_run_bounded` as described above; no other defects).
./marathon-system/2026-09-01-xyz-harness-quickwins--p2-turn-supervision/RELAY.md:101:   - `utils/py/rtl.py`: swept file: yes (`rtl_run_bounded` correctly sets `start_new_session=True`).
./marathon-system/2026-09-01-xyz-harness-quickwins--p2-turn-supervision/RELAY.md:102:   - `utils/py/relay_drive.py`: swept file: yes (GH-370 progress telemetry polling loop correctly implements dynamic `rtl-wt.*` worktree discovery and main tree fallback with changed-file counting).
./marathon-system/2026-09-01-xyz-harness-quickwins--p2-turn-supervision/RELAY.md:103:   - `test/gh369-group-kill.sh`: swept file: yes (fixture correctly tests both Bash and Python group-kill contracts once the runner race is resolved).
./marathon-system/2026-09-01-xyz-harness-quickwins--p2-turn-supervision/RELAY.md:104:   - `test/gh370-progress-telemetry.sh`: swept file: yes (passes 4/4).
./marathon-system/2026-09-01-xyz-harness-quickwins--p2-turn-supervision/RELAY.md:119:swept file: yes
./marathon-system/2026-09-01-xyz-harness-quickwins--p2-turn-supervision/RELAY.md:138:   - `relay-automation/relay-turn-lib.sh`: swept file: yes (clean, no defects).
./marathon-system/2026-09-01-xyz-harness-quickwins--p2-turn-supervision/RELAY.md:139:   - `utils/py/rtl.py`: swept file: yes (clean, no defects).
./marathon-system/2026-09-01-xyz-harness-quickwins--p2-turn-supervision/RELAY.md:140:   - `utils/py/relay_drive.py`: swept file: yes (clean, no defects).
./marathon-system/2026-09-01-xyz-harness-quickwins--p2-turn-supervision/RELAY.md:141:   - `test/gh369-group-kill.sh`: swept file: yes (clean, passes 6/6).
./marathon-system/2026-09-01-xyz-harness-quickwins--p2-turn-supervision/RELAY.md:142:   - `test/gh370-progress-telemetry.sh`: swept file: yes (clean, passes 4/4).
./marathon-system/2026-09-01-xyz-harness-quickwins--p2-turn-supervision/RELAY.md:165:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/relay-turn-lib.sh,utils/py/rtl.py,utils/py/relay_drive.py,test/gh369-group-kill.sh,test/gh370-progress-telemetry.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./marathon-system/gh-629/ESCALATION.md:16:I have reviewed the changes, confirmed that all the acceptance criteria are met, and verified that there are no latent defects in the modified files. I appended the required review block with `swept file: yes`, updated the status to `Approved`, and marked the turn as `done` using the `tick` binary. 
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:571:    23	     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:576:    28	     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:609:    61	  Graded findings ([Blocker]/[Should]/[Nit]/[Pass]) with citations; `swept file:` line. End the
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:628:    80	swept file: yes
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:668:   120	swept file: yes
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:699:   151	cleared. Same output contract (`swept file:`, `VERDICT: PASS|FAIL|PARKED`, `Basis:`).
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:703:   155	swept file: yes
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:736:   188	output contract (`swept file:`, `VERDICT: PASS|FAIL|PARKED`, `Basis:`).
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:740:   192	swept file: yes
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:773:   225	Round 5 requested. Same output contract: `swept file:`, `VERDICT: PASS|FAIL|PARKED`, `Basis:`.
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:777:   229	swept file: yes
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:806:   258	Round 6 requested (second and final authorized cycle). Same output contract: `swept file:`,
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:811:   263	swept file: yes
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:2809:| Aider + OpenRouter | `openrouter/qwen/qwen3.8-max` | Cloud | Advisory review **under supervision only** — never unattended; builder untested on this exact route | **C** | **The model's review content was the strongest recorded this day; the Aider reviewer SEAM is what fails.** Turn 1 landed a correct, fully-cited 7-blocker review with zero false positives. Turn 2 on the same thread produced no findings at all — the model entered a meta-loop about its own output format (whether to edit the `NEXT:` line, how to nest triple-backtick fences when echoing a file containing them) — and `aider-turn.sh`'s GH-251 salvage then appended ~1,200 lines of raw chain-of-thought into the relay file as if it were review content. Budget a human to read and truncate after **every** turn. The shim's qwen brevity instruction (`aider-turn.sh:145-147`, "under 50 words") does not hold on review-only turns. **SECOND USAGE 2026-08-20 (GH-111 + GH-108 code QA) — same split, sharper.** One `--review-once` turn against a 1,944-line diff: 13m 44s wall clock, verdict *Changes requested*, 0 Blockers, 2 `[Should]`, 3 `[Nit]`, 16 `[Pass]` each carrying a file/symbol citation, plus an honest `swept file: yes`. **Every finding was reproduced by the operator before acceptance and every one held** — two real regex false positives that refused a correctly scored entry, one under-graded correctness gap (baseline provenance was mutable; upgraded to Should and shipped as migration 005), one cosmetic bug. Zero hallucinated findings. **The seam failed the same way again:** the model did not append to the relay file; GH-251 salvage recovered the review from the transcript. New datum — the salvage output was **usable this time** (~1,200 lines of thinking with a correctly graded review at the end), so the salvage is not purely a noise amplifier; but 1 of 3 review turns has now landed natively, which is why this stays **C** and not a promotion. | [#111](https://github.com/HiQS-Labs/XYZ-forge/issues/111), [#108](https://github.com/HiQS-Labs/XYZ-forge/issues/108); relays `relay-system/2026-08-20/gh111-dialed-in-qa.md` (usage 1) and `relay-system/2026-08-20/gh111-gh108-qa.md` (usage 2, with the operator's finding-by-finding adjudication) |
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:2938:| **2026-08-22** | Aider + OpenRouter + `stealth/ox-alpha`, **reviewer role** | Added **C** | First use of this route, driven via `relay-drive.sh --review-once`, `ALLOW_PATHS=""`, worktree isolation ON, against `skills/ci-doctor/benchmark-runners.sh` (GH-161, PR #162). **R1: Blocked, correctly.** The turn-taker's `--artifact-file` seeding hadn't landed in the reviewer's context yet; the model declared `swept file: no` and refused to fabricate `[Pass]` findings against code it hadn't read — the honest failure mode, not a hallucination. **R2 (re-run after the artifact was seeded): the strongest first-attempt content seen from a new route.** Full 162-line static read, `swept file: yes`, verdict *Changes requested* with 2 `[Blocker]`, 4 `[Should]`, 5 `[Nit]`, 5 cited `[Pass]`. **Every finding verified true** against the real file before the operator acted: a `sed`-vs-literal mismatch that could silently commit a byte-identical no-op benchmark (undermining the tool's entire premise — GH-161's own header claims this exact failure mode impossible), and an unfiltered `gh run list --branch` pickup that could grab a wrong (push-triggered fast-lane, or cancelled) run instead of the dispatched one. Both confirmed by direct code inspection plus a targeted smoke test reproducing the reviewer's exact repro case (`runs-on: [self-hosted, linux]`) before fixing. Zero hallucinated findings; zero uncited Passes. **Delivery — mixed, root cause identified, not a model defect.** R1→R2 required a manual re-seed (environment/tooling gap). The R3 re-sweep (verifying the Producer's fixes) **timed out at the 900s wall-clock cap** (`aider-turn` exit 7) — but the turn's own log shows the model generated a full, well-formed second review in one clean LLM call (8.4k sent / 29k received, no retries) before the kill. Root cause: `aider-turn` ran `openrouter/stealth/ox-alpha` under Aider's default `whole` edit format (not in Aider's `model-settings.yml`), and the model wrote its response in diff-style (`+`-prefixed) lines, which `whole` format cannot parse as a file replacement — no error, no reflection, the turn simply idled with a correct response already sitting unused in the log until the wall-clock kill. This is the pre-existing, already-documented GH-118 edit-format quirk (see `skills/open-router/SKILL.md` and `relay-automation/README.md`, now updated with this model), not a reasoning or reliability failure of the model itself — the fix is `AIDER_FLAGS=--edit-format diff`, applied proactively for any new/unlisted OpenRouter model going forward. **Net: content quality is the strongest first-attempt showing of any route in this registry (2 real Blockers, zero hallucination, zero uncited Passes, twice); the one incomplete turn was a known, fixed harness-configuration gap, not the model.** Fixes verified independently (`bash -n`, `shellcheck -S error`, targeted smoke tests) rather than by the stalled R3 turn. **R3 re-run with `AIDER_FLAGS=--edit-format diff` applied: a second, different delivery failure.** Edit format was no longer the blocker, but the model then attempted an off-lane edit (outside the reviewer's `ALLOW_PATHS=""` scope) — `relay-turn-lib.sh`'s containment correctly discarded it and failed the turn (exit 6). Safety boundary held; nothing was lost or corrupted. **Closing the loop here** (operator-set boundary, no further root-causing): two independent delivery failures across three turns (timeout, then a containment violation) against one clean, high-quality review (R2) is not yet a route to trust unattended. Grade holds at **C** — real intelligence, unproven delivery, now on its second distinct failure mode rather than a resolved one. Verification of PR #162's actual code fixes stands independently of this stalled automated loop and does not depend on it closing. [#161](https://github.com/HiQS-Labs/XYZ-forge/issues/161), [#162](https://github.com/HiQS-Labs/XYZ-forge/pull/162); relay `relay-system/2026-08-22/ci-doctor-qa-gh-161-pr-162.md`. |
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:2941:| **2026-08-20** | Aider + OpenRouter + Qwen 3.8-Max, **reviewer role — 2nd reported usage** | **C confirmed, not promoted** | Second review turn on this route, against CODE this time (the 1,944-line GH-111 + GH-108 diff) rather than a plan doc. `--review-once`, `ALLOW_PATHS=""`, worktree isolation ON, 13m 44s. **Content: the strongest signal-to-noise yet.** Verdict *Changes requested* with 0 Blockers, 2 `[Should]`, 3 `[Nit]`, 16 cited `[Pass]`, and a declared `swept file: yes`. The operator reproduced every finding before acting: both `[Should]`s were live regex false positives that refused a correctly scored ROADMAP entry, and one `[Nit]` was under-graded — `baseline_source` was mutable, letting a `backfilled` baseline be quietly relabelled `observed`, which is a correctness gap in the metric and shipped as migration 005. **Zero hallucinated findings; zero uncited Passes.** **Delivery: failed identically to usage 1** — no relay-file append, GH-251 salvage recovered the review from the transcript. The salvage output was *usable* this time, which is new, but native delivery now stands at 1 of 3 turns. **Net: the grade holds at C for exactly the reason the registry already states — one good turn is not evidence the seam is fixed, and two good turns out of three still means a human reads every one.** [#111](https://github.com/HiQS-Labs/XYZ-forge/issues/111), [#108](https://github.com/HiQS-Labs/XYZ-forge/issues/108); relay `relay-system/2026-08-20/gh111-gh108-qa.md`. |
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:3112:| GH-91 · a build turn has nowhere to write verification output | ✅ | [GH-91-RELAY-SCRATCH-DIR.md](PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md) · [#91](https://github.com/HiQS-Labs/XYZ-forge/issues/91) |
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4151:    23	     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4156:    28	     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4189:    61	  Graded findings ([Blocker]/[Should]/[Nit]/[Pass]) with citations; `swept file:` line. End the
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4208:    80	swept file: yes
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4248:   120	swept file: yes
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4279:   151	cleared. Same output contract (`swept file:`, `VERDICT: PASS|FAIL|PARKED`, `Basis:`).
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4283:   155	swept file: yes
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4316:   188	output contract (`swept file:`, `VERDICT: PASS|FAIL|PARKED`, `Basis:`).
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4320:   192	swept file: yes
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4353:   225	Round 5 requested. Same output contract: `swept file:`, `VERDICT: PASS|FAIL|PARKED`, `Basis:`.
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4357:   229	swept file: yes
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4386:   258	Round 6 requested (second and final authorized cycle). Same output contract: `swept file:`,
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4391:   263	swept file: yes
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4459:   151	cleared. Same output contract (`swept file:`, `VERDICT: PASS|FAIL|PARKED`, `Basis:`).
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4463:   155	swept file: yes
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4496:   188	output contract (`swept file:`, `VERDICT: PASS|FAIL|PARKED`, `Basis:`).
./relay-system/2026-09-06/gh460-disposition-consult-113216/gh460-disposition-consult.codex.md:4500:   192	swept file: yes
./marathon-system/gh-629/RELAY.md:82:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/merge-cleanup/scripts/merge_cleanup.py,skills/merge-cleanup/SKILL.md,test/gh534_phase_c_tests.py,test/gh549-work-events.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./marathon-system/gh-629/RELAY.md:112:swept file: yes
./relay-system/2026-08-18/gh37-gh38-doorbell-hardening-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-08-18/gh37-gh38-doorbell-hardening-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-08-18/gh37-gh38-doorbell-hardening-qa.md:617:swept file: yes
./relay-system/2026-08-18/gh37-gh38-doorbell-hardening-qa.md:697:swept file: yes
./relay-system/2026-08-18/gh37-gh38-doorbell-hardening-qa.md:754:swept file: yes
./marathon-system/gh-414/RELAY.md:88:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/pdda/pdda.sh,test/gh414-comment-reference-check.sh,test/baselines/GH-414-negative-control.md,test/gh165-governance-canonical-paths-guard.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh280-jog-marathon-adapter.sh,test/gh284-p3-release-milestone.sh,test/gh35-test-tiers.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh365-pdda-gov-scan.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-hardening.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/pdda-local-checks.sh,test/pdda-repo-contract.sh,test/pdda-roadmap-coverage.sh,test/sentinel-overlay.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./marathon-system/gh-414/RELAY.md:128:swept file: yes
./relay-automation/new-relay.sh:86:     **Declare it: every review block must contain a literal \`swept file: yes\` or \`swept file: no\`
./relay-automation/new-relay.sh:91:     \`[Unverified — no citation]\` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-13/pr600-agy-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-13/pr600-agy-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-13/pr600-agy-qa.md:61:swept file: yes
./relay-system/2026-09-13/pr600-agy-qa.md:85:swept file: yes
./marathon-system/gh355-p1/RELAY.md:85:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,releases.sql,releases.db,test/gh32-releases-app.sh,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh107-timeline-json-seam.sh,test/gh153-releases-sidebar-rollup.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh291-contract-goldens.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh351-manifest-unship.sh,test/gh353-vendored-router-audit.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh39-releases-project-sync.sh,test/gh402-board-sync.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/gh77-standup-triage.sh,test/hq-rollup.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./marathon-system/gh355-p1/RELAY.md:168:swept file: yes
./relay-system/2026-09-13/pr599-deepseek-v41-flash-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-13/pr599-deepseek-v41-flash-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-13/pr599-deepseek-v41-flash-qa.md:1264:**Sweep:** swept file: yes. Pre-existing defects: 
./relay-system/2026-09-13/pr599-deepseek-v41-flash-qa.md:1407:I need to include `swept file: yes` and `VERDICT:` and `Basis`.
./relay-system/2026-09-13/pr599-deepseek-v41-flash-qa.md:1414:swept file: yes — read the full `utils/py/wave_reconcile.py`, 
./relay-system/2026-09-13/pr599-deepseek-v41-flash-qa.md:1500:**Pre-existing defects in swept files**
./relay-system/2026-09-13/pr599-deepseek-v41-flash-qa.md:1606:swept file: yes — read the full `utils/py/wave_reconcile.py`, 
./relay-system/2026-09-13/pr599-deepseek-v41-flash-qa.md:1692:**Pre-existing defects in swept files**
./relay-system/2026-09-13/gh605-sol-build.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-13/gh605-sol-build.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./marathon-system/p1-gh8/RELAY.md:82:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: bin/tick,src/events.js,test/unit/cli.test.js,test/unit/lock.test.js,test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh14-atomic-append.sh,test/gh148-deepseek-turn.sh,test/gh292-worktree-vendored-discovery.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-sync-check.sh,test/xyz-vendor.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./marathon-system/p1-gh8/RELAY.md:108:swept file: yes
./marathon-system/p1-gh8/RELAY.md:126:swept file: yes
./marathon-system/p1-gh8/RELAY.md:144:swept file: yes
./relay-system/2026-09-13/gh605-plan-agy.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-13/gh605-plan-agy.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-13/gh605-plan-agy.md:56:Plan review only. Never run validate.sh or test/*.sh in your linked reviewer worktree. Do not edit production code or the plan. Review inputs are committed. Use textual-only basis for the plan. End with VERDICT: PASS/FAIL/PARKED, swept file: yes/no, and header STATUS consistent with verdict. The driver owns commits; do not run git commit, push, or amend. Use the exact absolute tick path provided by the runtime prompt for token commands.
./relay-system/2026-09-13/gh605-plan-agy.md:88:swept file: yes
./relay-system/2026-09-13/gh605-plan-agy.md:107:swept file: yes
./relay-system/2026-09-13/gh605-plan-qwen-alibaba.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-13/gh605-plan-qwen-alibaba.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-13/gh605-plan-qwen-alibaba.md:63:all previous body text. Include exact VERDICT: PASS, FAIL or PARKED and swept file: yes/no,
./relay-automation/README.md:26:| `relay-turn-lib.sh` | **Shared safety core** (sourced, not run): the model-agnostic containment contract — path-allowlist + commit-bypass guard + no-push. Both headless turn-takers source this so the boundary lives in ONE place. See [decisions/2026-06-15-unattended-agent-containment.md](../decisions/2026-06-15-unattended-agent-containment.md). |
./evidence/marathons/run-3/ANALYSIS.md:38:and a requested regression test. It declared `swept file: yes` every round and ran
./relay-automation/relay-turn-lib.sh:5:# Containment contract — decisions/2026-06-15-unattended-agent-containment.md (3-model validated):
./relay-automation/relay-turn-lib.sh:6:#   (1) path-allowlist      — revert + FAIL on any change outside {relay file, ALLOW_PATHS}.
./relay-automation/relay-turn-lib.sh:374:  # GH-173 B3: remember reviewer-turn-ness for rtl_enforce (called AFTER the turn, by which point the
./relay-automation/relay-turn-lib.sh:820:  # GH-91: the sanctioned scratch dir. The harness REQUIRES the builder to verify its work by
./relay-automation/relay-turn-lib.sh:895:    # GH-91: builder scratch / verification output — sanctioned, writable by design, exempt with
./relay-automation/relay-turn-lib.sh:1048:  # GH-91: name the scratch affordance at the point of use — prose in a phase brief ("use \$TMPDIR")
./relay-automation/relay-turn-lib.sh:1115:# Deliberately NARROW — this is a room, not an amnesty (same line GH-91 drew for .relay-scratch):
./relay-automation/relay-turn-lib.sh:1150:  # GH-91: same sanction on the non-worktree path, but here the dir lives in RTL_ROOT itself —
./relay-automation/relay-turn-lib.sh:1184:# GH-173 B3 / GH-178 A4 follow-up (code review on PR #184): the claim-trigger and citation regexes
./relay-automation/relay-turn-lib.sh:1209:# GH-173 B3: mechanical uncited-"verified" check. new-relay.sh's own Reviewer template ("▶ TAKE YOUR
./relay-automation/relay-turn-lib.sh:1382:  # GH-91 (PR #93 review): scratch must not survive the turn EVEN WHEN the host repo gitignores
./relay-automation/relay-turn-lib.sh:1388:  # GH-173 B3: downgrade any uncited [Pass]/verified Reviewer finding BEFORE staging, so the fix lands
./evidence/marathons/run-3/3a-agy-quota-halt/marathon-r3p1-140238.md:63:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/sort.js,test/sort.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-06/gh460-final-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-06/gh460-final-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-06/gh460-final-qa.md:64:  Graded findings with citations; `swept file:` line; end with line-start `VERDICT: PASS` /
./relay-system/2026-09-06/gh460-final-qa.md:80:swept file: no
./relay-system/2026-09-06/gh460-final-qa.md:123:swept file: no
./relay-system/2026-09-06/gh460-final-qa.md:168:swept file: no
./relay-system/2026-09-06/gh460-final-qa.md:211:swept file: no
./relay-system/2026-09-06/gh460-final-qa.md:306:swept file: no
./relay-automation/claude-turn.sh:31:# gemini-turn.sh (decisions/2026-06-15-unattended-agent-containment.md).
./evidence/marathons/run-2/artefacts/transcripts/marathon-r2p3-135555.md:69:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/reconcile.js,test/reconcile.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./evidence/marathons/run-2/artefacts/transcripts/marathon-r2p3-135555.md:115:swept file: yes
./evidence/marathons/run-3/3a-agy-quota-halt/RELAY.md:63:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/sort.js,test/sort.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-automation/relay-loop.sh:53:#                 boundary (relay-turn-lib.sh path-allowlist / commit-bypass
./relay-system/2026-09-06/gh-478-plan-qa-ate-runaway-guard.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-06/gh-478-plan-qa-ate-runaway-guard.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-06/gh-478-plan-qa-ate-runaway-guard.md:87:swept file: yes
./relay-system/2026-09-06/gh-478-plan-qa-ate-runaway-guard.md:120:swept file: yes
./relay-system/2026-09-06/gh-478-plan-qa-ate-runaway-guard.md:154:swept file: yes
./relay-system/2026-09-06/gh-478-plan-qa-ate-runaway-guard.md:189:swept file: yes
./relay-system/2026-09-06/gh-478-plan-qa-ate-runaway-guard.md:193:- [Blocker] The claimed one-copy kill consolidation is false in the swept file. `_runaway_guard_kill_group` still contains its own TERM/probe/grace/KILL implementation (`test/lib/runaway-guard.sh:56`; `test/lib/runaway-guard.sh:70`) even though the active reaper delegates to `proc_group.py` (`test/lib/runaway-guard.sh:76`; `test/lib/runaway-guard.sh:81`), contradicting the artifact's “group killing exists exactly once” claim (`.relay-artifacts/GH-478-ATE-RUNAWAY-GUARD.md:36`). Fix: delete the dead Bash implementation and add a source/static assertion preventing a second kill implementation from returning.
./relay-system/2026-08-20/gh111-gh108-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-08-20/gh111-gh108-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-08-20/gh111-gh108-qa.md:1085:swept file: yes (I read the entire diff including all four files)               
./relay-system/2026-08-20/gh111-gh108-qa.md:1122: +swept file: yes                                                               
./evidence/marathons/run-2/artefacts/transcripts/marathon-r2p2-135246.md:67:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/balance.js,test/balance.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./evidence/marathons/run-2/artefacts/transcripts/marathon-r2p2-135246.md:108:swept file: yes
./relay-automation/CROSSMODEL-OPTIONA-PLAN.md:23:> The containment contract below (path-allowlist + commit-bypass guard + no-push) is recorded in
./relay-automation/CROSSMODEL-OPTIONA-PLAN.md:24:> [../decisions/2026-06-15-unattended-agent-containment.md](../decisions/2026-06-15-unattended-agent-containment.md)
./test/marathon-plan.sh:279:mk_doc "$I" GH-910-epic.md 2 2 2 "$(contract_for MISS_E2 src/epic.js)"
./test/marathon-plan.sh:284:- **GH-910 · epic umbrella** 🆕 — sequences the sub-issue [#911](https://github.com/o/r/issues/911) → [d](PROJECT/2-WORKING/GH-910-epic.md) · [#910](https://github.com/o/r/issues/910)
./test/marathon-plan.sh:287:{ [[ "$(wave_of "$doc" 910)" == "1" ]] && ! grep -q "already-closed" <<<"$out"; } && pass "I: title GH-910 wins over the in-prose closed #911 (item stays active, not already-closed) [agy Blocker r4]" || fail "I: ghIssueOf precedence wrong — $(grep -E 'already-closed' <<<"$out" | head -1)"
./relay-system/2026-08-20/marathon-r1p1-131459.md:63:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/export-csv.js,test/export-csv.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./evidence/marathons/run-2/artefacts/transcripts/marathon-r2p1-134950.md:72:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/money.js,test/money.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./evidence/marathons/run-2/artefacts/transcripts/marathon-r2p1-134950.md:109:swept file: yes
./evidence/marathons/run-2/artefacts/transcripts/marathon-r2p1-134950.md:134:swept file: yes
./evidence/marathons/run-2/artefacts/transcripts/marathon-r2p1-134950.md:137:- Confirmed direct decimal parsing, `E_PRECISION` handling, two-decimal rendering, exact largest-remainder allocation (including negative and boundary cases), and input validation. No pre-existing defects found in either swept file.
./evidence/marathons/run-2/artefacts/transcripts/marathon-r2p4-140017.md:66:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/report.js,test/report.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./evidence/marathons/run-2/artefacts/transcripts/marathon-r2p4-140017.md:111:- swept file: yes
./evidence/marathons/run-2/artefacts/transcripts/marathon-r2p4-140017.md:112:- Reviewed the complete `src/report.js` and `test/report.test.js`, plus the upstream reconciliation and money contracts. No pre-existing defects found in the swept files.
./relay-system/2026-09-13/gh605-expanded-plan.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-13/gh605-expanded-plan.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-13/gh605-expanded-plan.md:63:graded file:line findings and exact VERDICT: PASS/FAIL/PARKED and swept file: yes/no, Basis textual
./relay-system/2026-09-13/gh605-expanded-plan.md:80:swept file: yes
./relay-system/2026-09-13/gh605-expanded-plan.md:104:swept file: yes
./relay-system/2026-09-13/pr600-deepseek-v41-flash-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-13/pr600-deepseek-v41-flash-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-13/pr600-deepseek-v41-flash-qa.md:120:+swept file: yes
./relay-system/2026-08-20/marathon-daybreak-wave-1-2026-08-20-015332.md:103:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-12/gh592-plan-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-12/gh592-plan-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-12/gh592-plan-qa.md:74:swept file: yes
./relay-system/2026-09-12/gh592-plan-qa.md:118:swept file: yes
./relay-system/2026-09-12/gh592-plan-qa.md:157:swept file: yes
./relay-system/2026-09-12/gh592-plan-qa.md:194:swept file: yes
./evidence/marathons/run-3/artefacts/relay-threads/run3-hard-ambiguous--r3p1/RELAY.md:67:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/sort.js,test/sort.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./evidence/marathons/run-3/artefacts/relay-threads/run3-hard-ambiguous--r3p1/RELAY.md:102:swept file: yes
./evidence/marathons/run-3/artefacts/relay-threads/run3-hard-ambiguous--r3p1/RELAY.md:122:swept file: yes
./evidence/marathons/run-3/artefacts/relay-threads/run3-hard-ambiguous--r3p1/RELAY.md:124:I swept `src/sort.js` and `test/sort.test.js` in full, including the pre-existing portions. The implementation now correctly treats only `amount` as numeric and compares `lineNo` lexically; the added regression test distinguishes those orderings. Unknown-key validation, explicit index-based stability, input-array immutability, and empty-key copy behavior meet the brief. I found no additional pre-existing defects in the swept files.
./relay-system/2026-08-20/gh103-branch-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-08-20/gh103-branch-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-08-20/gh103-branch-qa.md:60:swept file: yes
./relay-system/2026-08-20/gh103-branch-qa.md:105:swept file: yes
./relay-automation/agy-turn.sh:27:# (decisions/2026-06-15-unattended-agent-containment.md).
./relay-system/2026-09-01/gh-365-qa-pr-378-test-suite-recalibration.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-01/gh-365-qa-pr-378-test-suite-recalibration.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-01/gh-365-qa-pr-378-test-suite-recalibration.md:49:  clean-tree, macOS promotion) is graded [Blocker]; `swept file:` declared.
./relay-system/2026-09-01/gh-365-qa-pr-378-test-suite-recalibration.md:88:`swept file: yes|no`; end with Verdict: Approved | Changes requested | Blocked.
./relay-system/2026-09-01/gh-365-qa-pr-378-test-suite-recalibration.md:102:swept file: yes
./evidence/marathons/run-3/artefacts/relay-threads/run3-hard-ambiguous--r3p3/RELAY.md:61:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/fuzzy-match.js,test/fuzzy-match.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./evidence/marathons/run-3/artefacts/relay-threads/run3-hard-ambiguous--r3p3/RELAY.md:103:swept file: yes
./evidence/marathons/run-3/artefacts/relay-threads/run3-hard-ambiguous--r3p3/RELAY.md:131:swept file: yes
./evidence/marathons/run-3/artefacts/relay-threads/run3-hard-ambiguous--r3p3/RELAY.md:133:Reviewed the complete current contents of `src/fuzzy-match.js` and `test/fuzzy-match.test.js`. The Round 1 sign correction is correctly implemented and covered. I found no other pre-existing defects in either swept file beyond the issue below.
./evidence/marathons/run-3/artefacts/relay-threads/run3-hard-ambiguous--r3p3/RELAY.md:179:swept file: yes
./evidence/marathons/run-3/artefacts/relay-threads/run3-hard-ambiguous--r3p3/RELAY.md:181:Reviewed the complete current contents of `src/fuzzy-match.js` and `test/fuzzy-match.test.js`, and ran `node --test test/fuzzy-match.test.js` successfully. The zero-tolerance correction is implemented correctly and has appropriate regression coverage. I found no other pre-existing defects in either swept file beyond the issue below.
./relay-system/2026-08-20/709506-agent2agent-gh-102-telemetry-architecture-gh-101-test-2-consult-dogf.md:52:**1. `consult.py --tool-mode programmatic` integration.** Copy the boundary `consult.sh` already proved rather than inventing one: each advisor runs in a throwaway git worktree cut from current state, and anything written there dies with it. Wire `script_runner.py` as the execution backend *inside* that worktree, and make it **fail-closed the same way GH-94 did** (fc9b0b3): if worktree creation or the seatbelt profile fails, refuse to start — never fall back to executing against the live tree. Three specifics: (a) keep the flag default-off and purely additive — the advisory contract (final text is the deliverable) is unchanged; programmatic mode only changes how the advisor gathers evidence; (b) give probe output a sanctioned home per the GH-91 `.relay-scratch/` precedent instead of a new ad-hoc category — a probe that has nowhere to write its evidence fails a green turn, which is the exact defect GH-91 retired; (c) telemetry: don't silently widen schema 1.0 — add `tool_mode` behind a versioned minor bump so `checkin.py` can still parse mixed logs, and keep `tokens_source` triage untouched.
./relay-system/2026-08-20/709506-agent2agent-gh-102-telemetry-architecture-gh-101-test-2-consult-dogf.md:71:   - Probe artifacts will write to the sanctioned `.relay-scratch/` directory per GH-91, with zero push and zero keychain access.
./skills/relay-automation/SKILL.md:21:| `relay-automation/codex-turn.sh` | **Option A** headless turn-taker: drives a Codex turn via `codex exec` behind a path-allowlist (no push) |
./skills/relay-automation/SKILL.md:22:| `relay-automation/agy-turn.sh` | **Option A** headless turn-taker: drives an agy turn via `agy -p` behind the same path-allowlist boundary (no push) |
./skills/relay-automation/SKILL.md:73:(dispatch-gated, path-allowlisted, no push).
./relay-system/2026-09-12/gh592-impl-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-12/gh592-impl-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-12/gh592-impl-qa.md:75:swept file: no
./relay-system/2026-09-12/gh592-impl-qa.md:125:swept file: no
./relay-system/2026-09-12/gh592-impl-qa.md:167:swept file: no
./relay-system/2026-09-08/gh494-layout-b-design.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-08/gh494-layout-b-design.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-08/gh494-layout-b-design.md:49:- Output concise cited findings and standalone VERDICT: PASS or VERDICT: FAIL, Basis: ..., swept file: yes. Set STATUS Approved when approved. The harness commits; do not run git or spawn reviewers.
./relay-system/2026-09-08/gh494-layout-b-design.md:63:swept file: yes
./evidence/marathons/run-3/artefacts/relay-threads/run3-hard-ambiguous--r3p2/RELAY.md:98:swept file: yes
./evidence/marathons/run-3/artefacts/relay-threads/run3-hard-ambiguous--r3p2/RELAY.md:108:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/decimal.js,test/decimal.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh491-p1-065607.md:83:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,utils/roadmap-dashboard.sh,test/gh491-roadmap-section-validation.sh,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh243-dashboard-staleness-guard.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-app.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh351-manifest-unship.sh,test/gh353-vendored-router-audit.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh39-releases-project-sync.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/hq-park-synthesis.sh,test/jog-queue.sh,test/roadmap-dashboard.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh491-p1-065607.md:146:swept file: yes
./relay-system/2026-08-20/marathon-daybreak-wave-2-2026-08-20-233212.md:106:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-021818.md:111:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-021818.md:135:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-021818.md:156:swept file: yes
./relay-system/2026-09-15/marathon-gh-625-070216.md:83:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/agent-chorus/scripts/agent_chorus_bridge.py,test/agent-chorus-bridge.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-15/marathon-gh-625-070216.md:110:swept file: yes
./relay-system/2026-09-08/marathon-gh491-p1-071101.md:83:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,utils/roadmap-dashboard.sh,test/gh491-roadmap-section-validation.sh,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh243-dashboard-staleness-guard.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-app.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh351-manifest-unship.sh,test/gh353-vendored-router-audit.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh39-releases-project-sync.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/hq-park-synthesis.sh,test/jog-queue.sh,test/roadmap-dashboard.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh491-p1-071101.md:146:swept file: yes
./relay-system/2026-08-21/gh141-fuzz-ate-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-08-21/gh141-fuzz-ate-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-08-21/gh141-fuzz-ate-qa.md:450:6. A literal `swept file: yes|no` line is present.
./relay-system/2026-08-21/gh141-fuzz-ate-qa.md:464:swept file: yes
./relay-system/2026-08-21/gh141-fuzz-ate-qa.md:692:swept file: yes
./relay-system/2026-08-21/gh141-fuzz-ate-qa.md:885:swept file: yes
./relay-system/2026-08-21/gh141-fuzz-ate-qa.md:1015:swept file: yes
./evidence/marathons/run-3/artefacts/relay-threads/run3-hard-ambiguous--r3p1.agy-quota-halt/RELAY.md:63:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/sort.js,test/sort.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./test/relay-uncited-findings.sh:2:# test/relay-uncited-findings.sh — GH-173 B3: mechanically prove rtl_check_uncited_findings() catches
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-011941.md:111:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-011941.md:137:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-011941.md:153:swept file: yes
./relay-system/2026-09-08/gh494-consumer-plan.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-08/gh494-consumer-plan.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-08/gh494-consumer-plan.md:51:- Do not build code, run source jobs/tests, modify governance or execute Git. Edit only this relay file. Driver handles commit/handoff. Append one concise review block with swept file: yes, standalone VERDICT: PASS or VERDICT: FAIL, Basis: text, cited actionable findings. Set STATUS: Approved only for PASS; otherwise leave Open and NEXT: Producer. Proposed tests are promises, not executed proof. Avoid cosmetic or speculative scope expansion.
./relay-system/2026-09-08/gh494-consumer-plan.md:65:swept file: yes
./relay-system/2026-09-08/gh494-consumer-plan.md:92:swept file: yes
./relay-system/2026-09-15/marathon-gh-624-072105.md:88:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/merge-cleanup/scripts/merge_cleanup.py,skills/merge-cleanup/SKILL.md,test/gh534_phase_c_tests.py,test/gh549-work-events.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-15/marathon-gh-624-072105.md:115:swept file: yes
./CHANGELOG.md:564:- **GH-91: `.relay-scratch/` — a sanctioned home for builder verification output.** A build
./CHANGELOG.md:1187:- **GH-173 B3 + GH-178 A1/A4**: three bounded patches from the #173/#178 beta-feedback backlog, landed together in one PR. **B3** (reviewer citation, #173): the Phase 2 read found the actual source of Jedi Wright's uncited "[Pass]" claim is `relay-automation/new-relay.sh`'s scaffolded Reviewer template — not `consult.sh`'s advisor PREAMBLE (which already asks advisors to cite evidence and showed unprompted citation in dogfooding) and not `relay-turn-lib.sh`'s generic `rtl_turn_prompt` role_note (which never defined the `[Pass]` grading scheme). Added one sentence requiring a quote or `file:line` citation on any `[Pass]`/"verified"/"confirmed" finding, backstopped by a new mechanical check (`rtl_check_uncited_findings()` in `relay-turn-lib.sh`, called from `rtl_enforce()` on Reviewer turns only) that rewrites an uncited claim to `[Unverified — no citation]` in place — catches the absence of a citation, not whether a present one is accurate. **A1** (advisor registry, #178): `consult.sh`'s `case "$m" in codex|agy|gemini|aider)` dispatch is now a data table (`ADV_NAMES`/`ADV_RUNFNS` parallel arrays), so adding a 5th advisor is a data addition, not a new case arm; wrote the "add vendor N+1" recipe into `relay-automation/README.md`. **A4** (verdict provenance, #178 — deliberately scoped down, NOT the full firsthand-vs-asserted taxonomy): reused A2's exact stdout+prepended-transcript+sidecar mechanism to stamp `NO FIRSTHAND VERIFICATION CITED — treat conclusions as conditional` on any answered advisor whose transcript has zero explicit citations anywhere; the fuller provenance distinction stays future-scoped. New tests: `test/relay-uncited-findings.sh` (8 assertions), plus 6 new assertions in `test/consult.sh` (A1: 3, A4: 3). Targeted regression sweep green across `test/consult.sh`, `test/agy-turn.sh`, `test/codex-turn.sh`, `test/claude-turn.sh`, `test/aider-turn.sh`, `test/shim-worktree.sh`, `test/relay-turn-trace.sh`, `test/new-relay.sh`, `test/relay-target-root.sh`, `test/relay-case-insensitive.sh`, `test/test-agy-isolation.sh`.
./CHANGELOG.md:1953:- **Containment inherited, not re-implemented:** the backgrounded process is the *same* runner, so the `relay-turn-lib.sh` boundary (path-allowlist / commit-bypass / no-push / worktree isolation) is byte-identical — `&` changes only *when* the parent returns, never the child's code path. Asserted by an fg/bg execution-parity test; the boundary itself stays owned by the kernel's own containment tests.
./CHANGELOG.md:2363:- **`relay-automation/agy-turn.sh`** — headless turn-taker for the Antigravity CLI (`agy`), mirroring `gemini-turn.sh` on the shared `relay-turn-lib.sh` containment core (same path-allowlist / commit-bypass / no-push contract). Invocation: `agy --dangerously-skip-permissions --print-timeout <cap>s -p <prompt>`; optional `AGY_MODEL` (agy is a multi-model gateway — Gemini / Claude / GPT-OSS) and `AGY_FLAGS`. Pre-authed off the signed-in Antigravity desktop app.
./CHANGELOG.md:2571:- `decisions/2026-06-15-unattended-agent-containment.md` — **Decided**: path-allowlist + commit-bypass guard + no-push is sufficient containment for an unattended committing agent. 3-model validated; revisit on the first real unattended Option-A run. Linked from RECAP, 4X4, CROSSMODEL-OPTIONA-PLAN.
./CHANGELOG.md:2590:- **`codex-turn.sh`**: drives a Codex relay turn via `codex exec` behind a hard path-allowlist — dispatches only for the Codex agent, reverts any off-lane edit + fails, commits file-scoped, **no push** (coordination is shared-local `.tick`). `test/codex-turn.sh` 10/10; `validate.sh` **19/19**.
./relay-system/2026-09-08/gh516-express-plan-qa-agy.md:19:     Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-08/gh516-express-plan-qa-agy.md:62:swept file: yes
./relay-system/2026-09-08/gh516-express-plan-qa-agy.md:99:swept file: yes
./relay-system/2026-09-15/marathon-gh-624-070333.md:83:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/merge-cleanup/scripts/merge_cleanup.py,skills/merge-cleanup/SKILL.md,test/gh534_phase_c_tests.py,test/gh549-work-events.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh421-p1-232210.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: validate.sh,.github/workflows/ci.yml,utils/py/wave_reconcile.py,.github/workflows/wave-reconcile.yml,test/gh421-auto-wave-reconcile.sh,test/baselines/GH-421-negative-control.md. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh421-p1-232210.md:119:**swept file: yes**
./relay-system/2026-09-08/marathon-gh421-p1-232210.md:173:**swept file: yes**
./relay-system/2026-09-08/marathon-gh421-p1-232210.md:221:**swept file: yes**
./relay-system/2026-09-08/marathon-gh421-p1-232210.md:265:**swept file: yes**
./relay-system/2026-08-21/marathon-daybreak-wave-3-2026-08-20-043806.md:110:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-3-2026-08-20-043806.md:140:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-3-2026-08-20-043806.md:154:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-3-2026-08-20-043806.md:178:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-191407.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,test/gh423-roadmap-render.sh,test/baselines/GH-423-negative-control.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-app.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh351-manifest-unship.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh39-releases-project-sync.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh423-p1-191407.md:145:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-191407.md:183:swept file: yes
./relay-system/2026-08-21/gh-124-127-merge-sequence-review.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-08-21/gh-124-127-merge-sequence-review.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-08-21/gh-124-127-merge-sequence-review.md:123:swept file: yes
./test/gh113-headless-scratch.sh:7:# OFF-ALLOWLIST and failed the turn (exit 6) even though the lane work itself was fine. GH-91 had
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-005836.md:111:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-005836.md:144:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-005836.md:175:Pre-existing defects in the swept files are in scope and are recorded above. I did not run an
./relay-system/2026-09-15/marathon-gh-629-073722.md:82:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/merge-cleanup/scripts/merge_cleanup.py,skills/merge-cleanup/SKILL.md,test/gh534_phase_c_tests.py,test/gh549-work-events.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-15/marathon-gh-629-073722.md:112:swept file: yes
./relay-system/2026-09-08/gh494-html-review.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-08/gh494-html-review.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-08/gh494-html-review.md:50:- Output only concise graded, cited findings, then standalone VERDICT: PASS or VERDICT: FAIL, Basis: ..., and swept file: yes. Set STATUS Approved only on approval. Harness owns commit; never run git commands or tests. No extra reviewers or harnesses.
./relay-system/2026-09-08/gh494-html-review.md:73:swept file: yes
./relay-system/2026-09-08/gh494-html-review.md:100:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-3-2026-08-20-035736.md:105:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-3-2026-08-20-035736.md:133:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-3-2026-08-20-035736.md:158:swept file: yes
./relay-system/2026-09-15/marathon-gh-629-074139.md:82:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/merge-cleanup/scripts/merge_cleanup.py,skills/merge-cleanup/SKILL.md,test/gh534_phase_c_tests.py,test/gh549-work-events.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-15/marathon-gh-629-074139.md:112:swept file: yes
./relay-system/2026-09-08/marathon-gh421-p1-235935.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: validate.sh,.github/workflows/ci.yml,utils/py/wave_reconcile.py,.github/workflows/wave-reconcile.yml,test/gh421-auto-wave-reconcile.sh,test/baselines/GH-421-negative-control.md. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh421-p1-235935.md:119:**swept file: yes**
./relay-system/2026-09-08/marathon-gh421-p1-235935.md:173:**swept file: yes**
./relay-system/2026-09-08/marathon-gh421-p1-235935.md:221:**swept file: yes**
./relay-system/2026-09-08/marathon-gh421-p1-235935.md:265:**swept file: yes**
./relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:1130:  "gh91-relay-scratch.sh"          # GH-91 (sanctioned .relay-scratch/ for builder verification output: exempted in rtl_check + rtl_worktree_end, pre-created by begin, named in the turn prompt; never copied back, discarded under ROOT; controls pin that stray writes and lookalike prefixes still go off-lane) — 15/0, driven at the lib-function level, no builder binary needed
./relay-system/2026-09-08/flightdeck-session-plan.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-08/flightdeck-session-plan.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-08/flightdeck-session-plan.md:68:swept file: yes — full reads of `.relay-artifacts/GH-494-SESSION-CONTEXT-PLAN.md`, `PROJECT/2-WORKING/recon-flightdeck-session-context.md`, `PROJECT/2-WORKING/GH-494-FLIGHT-DASHBOARD.md`, `src/flightdeck/connectors.py`, `src/flightdeck/aggregate.py`, `src/flightdeck/contract.py`, `src/flightdeck/__init__.py`, `web/flightdeck/app.js`, `web/flightdeck/issue-context.mjs`. No pre-existing defects found in touched files: the existing CLIO reader, aggregation, and browser modules are sound for their current scope. The specific concern — `read_clio` overwriting the `task` field with every latest prompt — is already acknowledged in the plan at item 4 and the recon map at seam line 72. The `REGISTRY` dict does not yet include a session-context connector; the plan correctly proposes adding one rather than hacking `read_clio` or `read_rebalance`. The `app.js` handoff logic at line 234–252 uses `lane.task` for context — the plan's proposed additive fields (earliest intent, session title) will require new consumer code; this is implicit in the plan but not a defect in the existing code.
./relay-system/2026-09-08/flightdeck-session-plan.md:122:**Re-review this:** All revised text, especially B1 and S1 source distinction. Your previous response failed structural validation (exit 8): include a standalone literal `VERDICT: Changes requested` or `VERDICT: Approved` line in your NEW reviewer block, as well as **Basis:** textual only and swept file: yes. Do not rewrite prior reviewer content. Plan QA only; no runtime execution.
./relay-system/2026-09-08/flightdeck-session-plan.md:128:swept file: yes — full reads of `.relay-artifacts/GH-494-SESSION-CONTEXT-PLAN.md`, `recon-flightdeck-session-context.md`, `GH-494-FLIGHT-DASHBOARD.md`, `connectors.py`, `aggregate.py`, `contract.py`, `__init__.py`, `app.js`, `issue-context.mjs`. No pre-existing defects found in the plan text after the Round 2 revisions.
./HARNESS-MODELS-REGISTRY.md:46:| Aider + OpenRouter | `openrouter/qwen/qwen3.8-max` | Cloud | Advisory review **under supervision only** — never unattended; builder untested on this exact route | **C** | **The model's review content was the strongest recorded this day; the Aider reviewer SEAM is what fails.** Turn 1 landed a correct, fully-cited 7-blocker review with zero false positives. Turn 2 on the same thread produced no findings at all — the model entered a meta-loop about its own output format (whether to edit the `NEXT:` line, how to nest triple-backtick fences when echoing a file containing them) — and `aider-turn.sh`'s GH-251 salvage then appended ~1,200 lines of raw chain-of-thought into the relay file as if it were review content. Budget a human to read and truncate after **every** turn. The shim's qwen brevity instruction (`aider-turn.sh:145-147`, "under 50 words") does not hold on review-only turns. **SECOND USAGE 2026-08-20 (GH-111 + GH-108 code QA) — same split, sharper.** One `--review-once` turn against a 1,944-line diff: 13m 44s wall clock, verdict *Changes requested*, 0 Blockers, 2 `[Should]`, 3 `[Nit]`, 16 `[Pass]` each carrying a file/symbol citation, plus an honest `swept file: yes`. **Every finding was reproduced by the operator before acceptance and every one held** — two real regex false positives that refused a correctly scored entry, one under-graded correctness gap (baseline provenance was mutable; upgraded to Should and shipped as migration 005), one cosmetic bug. Zero hallucinated findings. **The seam failed the same way again:** the model did not append to the relay file; GH-251 salvage recovered the review from the transcript. New datum — the salvage output was **usable this time** (~1,200 lines of thinking with a correctly graded review at the end), so the salvage is not purely a noise amplifier; but 1 of 3 review turns has now landed natively, which is why this stays **C** and not a promotion. | [#111](https://github.com/HiQS-Labs/XYZ-forge/issues/111), [#108](https://github.com/HiQS-Labs/XYZ-forge/issues/108); relays `relay-system/2026-08-20/gh111-dialed-in-qa.md` (usage 1) and `relay-system/2026-08-20/gh111-gh108-qa.md` (usage 2, with the operator's finding-by-finding adjudication) |
./HARNESS-MODELS-REGISTRY.md:175:| **2026-08-22** | Aider + OpenRouter + `stealth/ox-alpha`, **reviewer role** | Added **C** | First use of this route, driven via `relay-drive.sh --review-once`, `ALLOW_PATHS=""`, worktree isolation ON, against `skills/ci-doctor/benchmark-runners.sh` (GH-161, PR #162). **R1: Blocked, correctly.** The turn-taker's `--artifact-file` seeding hadn't landed in the reviewer's context yet; the model declared `swept file: no` and refused to fabricate `[Pass]` findings against code it hadn't read — the honest failure mode, not a hallucination. **R2 (re-run after the artifact was seeded): the strongest first-attempt content seen from a new route.** Full 162-line static read, `swept file: yes`, verdict *Changes requested* with 2 `[Blocker]`, 4 `[Should]`, 5 `[Nit]`, 5 cited `[Pass]`. **Every finding verified true** against the real file before the operator acted: a `sed`-vs-literal mismatch that could silently commit a byte-identical no-op benchmark (undermining the tool's entire premise — GH-161's own header claims this exact failure mode impossible), and an unfiltered `gh run list --branch` pickup that could grab a wrong (push-triggered fast-lane, or cancelled) run instead of the dispatched one. Both confirmed by direct code inspection plus a targeted smoke test reproducing the reviewer's exact repro case (`runs-on: [self-hosted, linux]`) before fixing. Zero hallucinated findings; zero uncited Passes. **Delivery — mixed, root cause identified, not a model defect.** R1→R2 required a manual re-seed (environment/tooling gap). The R3 re-sweep (verifying the Producer's fixes) **timed out at the 900s wall-clock cap** (`aider-turn` exit 7) — but the turn's own log shows the model generated a full, well-formed second review in one clean LLM call (8.4k sent / 29k received, no retries) before the kill. Root cause: `aider-turn` ran `openrouter/stealth/ox-alpha` under Aider's default `whole` edit format (not in Aider's `model-settings.yml`), and the model wrote its response in diff-style (`+`-prefixed) lines, which `whole` format cannot parse as a file replacement — no error, no reflection, the turn simply idled with a correct response already sitting unused in the log until the wall-clock kill. This is the pre-existing, already-documented GH-118 edit-format quirk (see `skills/open-router/SKILL.md` and `relay-automation/README.md`, now updated with this model), not a reasoning or reliability failure of the model itself — the fix is `AIDER_FLAGS=--edit-format diff`, applied proactively for any new/unlisted OpenRouter model going forward. **Net: content quality is the strongest first-attempt showing of any route in this registry (2 real Blockers, zero hallucination, zero uncited Passes, twice); the one incomplete turn was a known, fixed harness-configuration gap, not the model.** Fixes verified independently (`bash -n`, `shellcheck -S error`, targeted smoke tests) rather than by the stalled R3 turn. **R3 re-run with `AIDER_FLAGS=--edit-format diff` applied: a second, different delivery failure.** Edit format was no longer the blocker, but the model then attempted an off-lane edit (outside the reviewer's `ALLOW_PATHS=""` scope) — `relay-turn-lib.sh`'s containment correctly discarded it and failed the turn (exit 6). Safety boundary held; nothing was lost or corrupted. **Closing the loop here** (operator-set boundary, no further root-causing): two independent delivery failures across three turns (timeout, then a containment violation) against one clean, high-quality review (R2) is not yet a route to trust unattended. Grade holds at **C** — real intelligence, unproven delivery, now on its second distinct failure mode rather than a resolved one. Verification of PR #162's actual code fixes stands independently of this stalled automated loop and does not depend on it closing. [#161](https://github.com/HiQS-Labs/XYZ-forge/issues/161), [#162](https://github.com/HiQS-Labs/XYZ-forge/pull/162); relay `relay-system/2026-08-22/ci-doctor-qa-gh-161-pr-162.md`. |
./HARNESS-MODELS-REGISTRY.md:178:| **2026-08-20** | Aider + OpenRouter + Qwen 3.8-Max, **reviewer role — 2nd reported usage** | **C confirmed, not promoted** | Second review turn on this route, against CODE this time (the 1,944-line GH-111 + GH-108 diff) rather than a plan doc. `--review-once`, `ALLOW_PATHS=""`, worktree isolation ON, 13m 44s. **Content: the strongest signal-to-noise yet.** Verdict *Changes requested* with 0 Blockers, 2 `[Should]`, 3 `[Nit]`, 16 cited `[Pass]`, and a declared `swept file: yes`. The operator reproduced every finding before acting: both `[Should]`s were live regex false positives that refused a correctly scored ROADMAP entry, and one `[Nit]` was under-graded — `baseline_source` was mutable, letting a `backfilled` baseline be quietly relabelled `observed`, which is a correctness gap in the metric and shipped as migration 005. **Zero hallucinated findings; zero uncited Passes.** **Delivery: failed identically to usage 1** — no relay-file append, GH-251 salvage recovered the review from the transcript. The salvage output was *usable* this time, which is new, but native delivery now stands at 1 of 3 turns. **Net: the grade holds at C for exactly the reason the registry already states — one good turn is not evidence the seam is fixed, and two good turns out of three still means a human reads every one.** [#111](https://github.com/HiQS-Labs/XYZ-forge/issues/111), [#108](https://github.com/HiQS-Labs/XYZ-forge/issues/108); relay `relay-system/2026-08-20/gh111-gh108-qa.md`. |
./relay-system/2026-09-08/marathon-p1-175055.md:35:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-004848.md:111:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-004848.md:141:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-004848.md:180:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-020120.md:111:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-020120.md:137:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-020120.md:162:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-020120.md:201:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-020120.md:225:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-190303.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,test/gh423-roadmap-render.sh,test/baselines/GH-423-negative-control.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-app.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh351-manifest-unship.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh39-releases-project-sync.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh423-p1-190303.md:145:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-190303.md:183:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-022518.md:111:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-2-2026-08-20-022518.md:143:swept file: yes
./relay-system/2026-09-08/marathon-p1-164751.md:35:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh425-p1-220534.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/wave_reconcile.py,test/gh425-gate-provenance-pr.sh,test/baselines/GH-425-negative-control.md. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh425-p1-220534.md:150:swept file: yes
./relay-system/2026-09-08/marathon-gh425-p1-220534.md:198:swept file: yes
./relay-system/2026-09-08/marathon-gh425-p1-220534.md:243:swept file: yes
./test/relay-loop.sh:101:#     containment boundary (path-allowlist/no-push, owned + tested by relay-turn-lib.sh) is
./relay-system/2026-08-21/marathon-daybreak-wave-3-2026-08-20-045634.md:110:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-3-2026-08-20-045634.md:134:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-3-2026-08-20-045634.md:153:swept file: yes
./relay-system/2026-09-08/marathon-p1-184802.md:35:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/gh494-modularity-token-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-08/gh494-modularity-token-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-08/gh494-modularity-token-qa.md:66:- Output one concise review block with `swept file: yes`, graded findings, concrete fixes, `Basis:`,
./relay-system/2026-09-08/gh494-modularity-token-qa.md:81:swept file: yes
./relay-system/2026-09-08/marathon-p1-190210.md:35:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh424-p1-203446.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,utils/py/wave_reconcile.py,ROADMAP-DASHBOARD.md,test/gh424-roadmap-status-marker.sh,test/baselines/GH-424-negative-control.md. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh424-p1-203446.md:142:swept file: yes
./relay-system/2026-09-08/marathon-gh424-p1-203446.md:183:swept file: yes
./relay-system/2026-09-08/marathon-gh424-p1-203446.md:226:swept file: yes
./relay-system/2026-09-08/flightdeck-504-code-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-08/flightdeck-504-code-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-08/flightdeck-504-code-qa.md:59:Review full files in src/flightdeck/, web/flightdeck/, test/flightdeck/ against PROJECT/2-WORKING/GH-494-FLIGHT-DASHBOARD.md. Inspect correctness, security, navigation, source isolation and issue visibility. Do not run validate.sh or test/*.sh in the worktree; the repository gate runs separately. Python focused tests and the manual harness are safe. Review only and modify only this relay file. Give concrete findings, with literal VERDICT: Approved or VERDICT: Changes requested and swept file: yes/no. Commit only the relay.
./relay-system/2026-09-08/flightdeck-504-code-qa.md:63:swept file: yes
./relay-system/2026-09-08/flightdeck-504-code-qa.md:88:swept file: yes
./relay-system/2026-09-08/marathon-p1-183342.md:35:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-3-2026-08-20-050645.md:110:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh355-p1-060346.md:85:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,releases.sql,releases.db,test/gh32-releases-app.sh,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh107-timeline-json-seam.sh,test/gh153-releases-sidebar-rollup.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh291-contract-goldens.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh351-manifest-unship.sh,test/gh353-vendored-router-audit.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh39-releases-project-sync.sh,test/gh402-board-sync.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/gh77-standup-triage.sh,test/hq-rollup.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh355-p1-060346.md:168:swept file: yes
./relay-system/2026-09-08/marathon-p1-163419.md:35:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh424-p1-204449.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,utils/py/wave_reconcile.py,ROADMAP-DASHBOARD.md,test/gh424-roadmap-status-marker.sh,test/baselines/GH-424-negative-control.md. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh424-p1-204449.md:142:swept file: yes
./relay-system/2026-09-08/marathon-gh424-p1-204449.md:183:swept file: yes
./relay-system/2026-09-08/marathon-gh424-p1-204449.md:226:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-3-2026-08-20-053145.md:110:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-3-2026-08-20-053145.md:135:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-3-2026-08-20-053145.md:163:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-175146.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,test/gh423-roadmap-render.sh,test/baselines/GH-423-negative-control.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-app.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh351-manifest-unship.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh39-releases-project-sync.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh423-p1-175146.md:145:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-175146.md:183:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-161741.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,test/gh423-roadmap-render.sh,test/baselines/GH-423-negative-control.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-app.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh351-manifest-unship.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh39-releases-project-sync.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh423-p1-161741.md:145:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-161741.md:183:swept file: yes
./relay-system/2026-09-08/marathon-p1-182541.md:35:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-p1-164041.md:35:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh423-p1-164843.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,test/gh423-roadmap-render.sh,test/baselines/GH-423-negative-control.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-app.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh351-manifest-unship.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh39-releases-project-sync.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh423-p1-164843.md:145:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-164843.md:183:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-4-2026-08-20-063406.md:117:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-4-2026-08-20-063406.md:123:pre-existing defect in those swept files that blocks this phase.
./relay-system/2026-08-21/marathon-daybreak-wave-4-2026-08-20-063406.md:144:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,skills/standup/install.sh,utils/ci-route.sh,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-4-2026-08-20-063406.md:179:swept file: yes
./evidence/marathons/run-3/artefacts/transcripts/marathon-r3p1-140238.md:63:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/sort.js,test/sort.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/gh494-layout-b-final.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-08/gh494-layout-b-final.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-08/gh494-layout-b-final.md:51:- Append concise cited findings plus standalone VERDICT: PASS or VERDICT: FAIL, Basis: ..., swept file: yes. Set STATUS Approved if approved. Harness commits, no git commands.
./relay-system/2026-09-08/gh494-layout-b-final.md:65:swept file: yes
./relay-system/2026-09-08/gh494-layout-b-final.md:94:swept file: yes
./relay-system/2026-09-09/gh537-five-plan-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-09/gh537-five-plan-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-09/gh537-five-plan-qa.md:72:swept file: yes
./relay-system/2026-09-09/gh537-five-plan-qa.md:113:swept file: yes
./relay-system/2026-09-08/gh494-connector-architecture-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-08/gh494-connector-architecture-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-08/gh494-connector-architecture-qa.md:66:- Output one concise block with `swept file: yes`, graded findings, concrete fixes,
./relay-system/2026-09-08/gh494-connector-architecture-qa.md:82:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-4-2026-08-20-060014.md:93:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,skills/standup/install.sh,utils/ci-route.sh,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-09/marathon-gh421-p1-015413.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: validate.sh,.github/workflows/ci.yml,utils/py/wave_reconcile.py,.github/workflows/wave-reconcile.yml,test/gh421-auto-wave-reconcile.sh,test/baselines/GH-421-negative-control.md. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-09/marathon-gh421-p1-015413.md:119:**swept file: yes**
./relay-system/2026-09-09/marathon-gh421-p1-015413.md:173:**swept file: yes**
./relay-system/2026-09-09/marathon-gh421-p1-015413.md:221:**swept file: yes**
./relay-system/2026-09-09/marathon-gh421-p1-015413.md:265:**swept file: yes**
./evidence/marathons/run-3/artefacts/transcripts/marathon-r3p1-141803.md:67:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/sort.js,test/sort.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./evidence/marathons/run-3/artefacts/transcripts/marathon-r3p1-141803.md:102:swept file: yes
./evidence/marathons/run-3/artefacts/transcripts/marathon-r3p1-141803.md:122:swept file: yes
./evidence/marathons/run-3/artefacts/transcripts/marathon-r3p1-141803.md:124:I swept `src/sort.js` and `test/sort.test.js` in full, including the pre-existing portions. The implementation now correctly treats only `amount` as numeric and compares `lineNo` lexically; the added regression test distinguishes those orderings. Unknown-key validation, explicit index-based stability, input-array immutability, and empty-key copy behavior meet the brief. I found no additional pre-existing defects in the swept files.
./relay-system/2026-09-08/marathon-gh454-p1-195039.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/timeline/export_timeline.py,utils/py/wave_reconcile.py,test/gh454-reconciler-defects.sh,test/gh103-timeline-exporter.sh,test/gh107-timeline-json-seam.sh,test/gh153-releases-sidebar-rollup.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh57-live-merge-resolve.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh454-p1-195039.md:119:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-4-2026-08-20-062030.md:98:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,skills/standup/install.sh,utils/ci-route.sh,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-4-2026-08-20-062030.md:122:swept file: yes
./relay-system/2026-08-21/marathon-daybreak-wave-4-2026-08-20-062030.md:144:swept file: yes
./relay-system/2026-09-08/marathon-p1-180637.md:35:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-09/gh537-five-impl-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-09/gh537-five-impl-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-09/gh537-five-impl-qa.md:154:swept file: yes
./relay-system/2026-09-09/gh537-five-impl-qa.md:271:swept file: yes
./relay-system/2026-09-09/gh537-five-impl-qa.md:345:swept file: yes
./evidence/marathons/run-3/artefacts/transcripts/marathon-r3p2-142117.md:98:swept file: yes
./evidence/marathons/run-3/artefacts/transcripts/marathon-r3p2-142117.md:108:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/decimal.js,test/decimal.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-3-2026-08-20-051932.md:110:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/standup/collect.sh,skills/standup/fixtures/,test/gh77-standup-triage.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-21/marathon-daybreak-wave-3-2026-08-20-051932.md:136:swept file: yes
./relay-system/2026-09-09/marathon-gh421-p1-014228.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: validate.sh,.github/workflows/ci.yml,utils/py/wave_reconcile.py,.github/workflows/wave-reconcile.yml,test/gh421-auto-wave-reconcile.sh,test/baselines/GH-421-negative-control.md. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-09/marathon-gh421-p1-014228.md:119:**swept file: yes**
./relay-system/2026-09-09/marathon-gh421-p1-014228.md:173:**swept file: yes**
./relay-system/2026-09-09/marathon-gh421-p1-014228.md:221:**swept file: yes**
./relay-system/2026-09-09/marathon-gh421-p1-014228.md:265:**swept file: yes**
./relay-system/2026-08-21/gh124-closeout-auto-pr-review.md:1473:    decisions/2026-06-15-unattended-agent-containment.md are referenced in      
./evidence/marathons/run-3/artefacts/transcripts/marathon-r3p3-143032.md:61:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/fuzzy-match.js,test/fuzzy-match.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./evidence/marathons/run-3/artefacts/transcripts/marathon-r3p3-143032.md:103:swept file: yes
./evidence/marathons/run-3/artefacts/transcripts/marathon-r3p3-143032.md:131:swept file: yes
./evidence/marathons/run-3/artefacts/transcripts/marathon-r3p3-143032.md:133:Reviewed the complete current contents of `src/fuzzy-match.js` and `test/fuzzy-match.test.js`. The Round 1 sign correction is correctly implemented and covered. I found no other pre-existing defects in either swept file beyond the issue below.
./evidence/marathons/run-3/artefacts/transcripts/marathon-r3p3-143032.md:179:swept file: yes
./evidence/marathons/run-3/artefacts/transcripts/marathon-r3p3-143032.md:181:Reviewed the complete current contents of `src/fuzzy-match.js` and `test/fuzzy-match.test.js`, and ran `node --test test/fuzzy-match.test.js` successfully. The zero-tolerance correction is implemented correctly and has appropriate regression coverage. I found no other pre-existing defects in either swept file beyond the issue below.
./relay-system/2026-08-26/marathon-p1-063934.md:88:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/xyz-vendor.sh,test/xyz-vendor.sh,skills/relay-xyz/SKILL.md,relay-automation/README.md,relay-automation/xyz-releases-onboard.sh,test/gh197-vendor-tier-split.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-26/marathon-p1-063934.md:143:swept file: yes
./relay-system/2026-08-26/marathon-p1-063934.md:189:swept file: yes
./relay-system/2026-08-26/marathon-p1-063934.md:214:swept file: yes
./relay-system/2026-08-26/marathon-p1-063934.md:243:swept file: yes
./relay-system/2026-09-08/marathon-gh418-p1-211320.md:84:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/marathon_plan.py,utils/py/_marathon_plan.py,test/gh418-planner-ledger-source.sh,test/baselines/GH-418-negative-control.md. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh418-p1-211320.md:123:swept file: yes
./relay-system/2026-09-08/gh494-layout-c-final.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-08/gh494-layout-c-final.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-08/gh494-layout-c-final.md:50:- Review only; no source edits, git commands, suite execution or unrelated governance work. Driver owns commits and handoff. Use source citations; browser evidence is producer-reported. Append one review block with literal swept file: yes, a standalone VERDICT: PASS or VERDICT: FAIL, and Basis: text. Set STATUS: Approved only for PASS, otherwise leave Open and name actionable defects. Return NEXT: Producer.
./relay-system/2026-09-08/gh494-layout-c-final.md:64:swept file: yes
./relay-system/2026-09-08/gh494-layout-c-final.md:92:swept file: yes
./relay-system/2026-08-26/gh255-gh256-final-qa.md:24:`swept file: yes` or `swept file: no` line.
./relay-system/2026-08-26/gh255-gh256-final-qa.md:78:swept file: yes
./relay-system/2026-09-09/gh536-relocation-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-09/gh536-relocation-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-09/gh536-relocation-qa.md:47:- Review questions: (1) Does each numbered execution step cite verifiable evidence (SHAs, counts, paths)? (2) Is any acceptance box ticked without support? (3) Is the rollback sequence mechanically complete? (4) SKILL.md: do any stale `Documents/Deployed Skills` references remain (grep the file)? (5) Whole-file sweep — declare `swept file: yes|no`. End with `VERDICT: PASS` or `VERDICT: FAIL` plus a `Basis:` line, and set STATUS: Approved if approving.
./relay-system/2026-09-09/gh536-relocation-qa.md:64:- `swept file: yes`
./relay-system/2026-09-08/gh494-design-review.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-08/gh494-design-review.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-08/gh494-design-review.md:63:swept file: yes
./relay-system/2026-09-08/gh494-design-review.md:86:Reviewer: review the revised brief, answer its Review questions and resolve R1–R3. Keep the response concise. Your appended block MUST contain standalone `VERDICT: PASS` (approval) or `VERDICT: FAIL`, plus `Basis: ...` and `swept file: yes`. Set STATUS Approved only if approved. Do not run suites or edit artifacts. The harness commits your relay change.
./relay-system/2026-09-08/gh494-design-review.md:95:swept file: yes
./relay-system/2026-09-09/gh508-spike-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-09/gh508-spike-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-09/gh508-spike-qa.md:56:6. **Whole-file sweep (GH-268):** pre-existing defects in the doc are in scope — declare `swept file: yes|no`.
./relay-system/2026-09-09/gh508-spike-qa.md:74:swept file: yes
./relay-system/2026-09-09/gh508-spike-qa.md:100:swept file: yes
./relay-system/2026-08-26/marathon-p1-062824.md:79:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/self_healer.py,test/gh182-healer-facade-safety.sh,validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-08-26/marathon-p1-062824.md:122:swept file: yes
./relay-system/2026-08-26/marathon-p1-062824.md:130:- **Pre-existing defect in the swept file:** `apply_unified_diff()` advertises unified-diff application but ignores hunk offsets and context validation, so a malformed or mismatched multi-hunk diff can silently rewrite the wrong content. It is not exercised by the new CLI flow, but it is public module functionality in the touched file. Either remove it if dead or make it fail closed with a focused regression test.
./relay-system/2026-08-26/marathon-p1-062824.md:156:swept file: yes
./relay-system/2026-08-26/marathon-p1-062824.md:196:swept file: yes
./relay-system/2026-08-26/marathon-p1-062824.md:230:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-163515.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,test/gh423-roadmap-render.sh,test/baselines/GH-423-negative-control.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-app.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh351-manifest-unship.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh39-releases-project-sync.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh423-p1-163515.md:145:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-163515.md:183:swept file: yes
./relay-system/2026-09-09/gh442-radar-sdlc-coach-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-09/gh442-radar-sdlc-coach-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-09/gh442-radar-sdlc-coach-qa.md:56:5. **Whole-file sweep (GH-268)**: Are there any residual contradictory instructions or tone mismatches elsewhere in `skills/radar/SKILL.md`? Declare `swept file: yes|no`.
./relay-system/2026-09-09/gh442-radar-sdlc-coach-qa.md:72:**swept file: yes**
./relay-system/2026-09-08/marathon-p1-184045.md:35:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh454-p1-200042.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/timeline/export_timeline.py,utils/py/wave_reconcile.py,test/gh454-reconciler-defects.sh,test/gh103-timeline-exporter.sh,test/gh107-timeline-json-seam.sh,test/gh153-releases-sidebar-rollup.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh57-live-merge-resolve.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh454-p1-200042.md:119:swept file: yes
./relay-system/2026-09-09/gh528-unstuck-qa.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-09/gh528-unstuck-qa.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-09/gh528-unstuck-qa.md:56:6. **Whole-file sweep (GH-268):** pre-existing defects in `skills/unstuck/SKILL.md` are in scope — declare `swept file: yes|no`.
./relay-system/2026-09-09/gh528-unstuck-qa.md:70:swept file: yes
./relay-system/2026-09-09/gh528-unstuck-qa.md:93:swept file: yes
./relay-system/2026-09-09/gh528-unstuck-qa.md:118:swept file: yes
./relay-system/2026-09-07/gh484-deploy-skills-plan.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/2026-09-07/gh484-deploy-skills-plan.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/2026-09-07/gh484-deploy-skills-plan.md:62:Write a concise Reviewer block with human **Verdict:** Approved / Changes requested / Blocked AND a separate plain `VERDICT: PASS` / `VERDICT: FAIL` / `VERDICT: PARKED` line (required by bin/validate-relay-block), Basis (textual only), swept file: yes/no, graded findings with file:line citations, and answers. PASS must mean Approved; FAIL means Changes requested. Do not run the full test suite from your worktree. No external messages or app mutations.
./relay-system/2026-09-07/gh484-deploy-skills-plan.md:84:**swept file: yes**
./relay-system/2026-09-07/gh484-deploy-skills-plan.md:109:**swept file: yes**
./relay-system/2026-09-08/marathon-gh355-p1-063159.md:85:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,releases.sql,releases.db,test/gh32-releases-app.sh,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh107-timeline-json-seam.sh,test/gh153-releases-sidebar-rollup.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh291-contract-goldens.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh351-manifest-unship.sh,test/gh353-vendored-router-audit.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh39-releases-project-sync.sh,test/gh402-board-sync.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/gh77-standup-triage.sh,test/hq-rollup.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh355-p1-063159.md:168:swept file: yes
./relay-system/gh613-final.md:23:     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
./relay-system/gh613-final.md:28:     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
./relay-system/gh613-final.md:46:- Definition of Done: Review the completed changes since ec0823abb084c62f494df4cd31432625f17a5c60 against the approved plan and five Opus findings. Full-source sweep the three Python modules; inspect the two narrow shell guards, tests and public docs. Verify actual shared helpers, auth/request restriction parity, strict success across auth modes, native effort and truthful telemetry, consult failure preservation, test falsifiability, and role/backward compatibility. Five mutants are rejected; native boundary control grants an extra fixture dir then denies it without that grant. Default CLI also denied outside reads: no prior data leak claimed. Existing consult process-group runner is unchanged; relay group/idle refactor is not claimed. The full pre-push gate is running independently; initial run exposed old metadata-only fake Claude results, now corrected in compatibility fixtures. Review code/evidence without claiming full-gate completion until the actual gate finishes. Only edit this relay; no test/*.sh, validate.sh or mutation scripts in the linked worktree. Return literal standalone VERDICT: PASS/FAIL and Basis: text, swept file: yes. Approve the implementation if sound; deployment/merge is not requested.
./relay-system/gh613-final.md:62:swept file: yes
./test/gh268-relay-cue-and-target-checks.sh:61:printf '%s' "$rendered" | grep -Fq "swept file: yes" \
./test/gh268-relay-cue-and-target-checks.sh:62:  && pass "new-relay requires an explicit 'swept file: yes/no' declaration" \
./test/gh268-relay-cue-and-target-checks.sh:63:  || fail "the sweep must be declared, not assumed — no 'swept file:' line required"
./test/gh268-relay-cue-and-target-checks.sh:64:grep -Fq "swept file: yes" "$py" \
./test/gh268-relay-cue-and-target-checks.sh:66:  || fail "marathon template does not require a 'swept file:' declaration"
./relay-system/2026-09-08/marathon-p1-162716.md:35:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-p1-161655.md:35:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-p1-185438.md:35:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh423-p1-183435.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,test/gh423-roadmap-render.sh,test/baselines/GH-423-negative-control.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-app.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh351-manifest-unship.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh39-releases-project-sync.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh423-p1-183435.md:145:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-183435.md:183:swept file: yes
./relay-system/2026-09-08/marathon-p1-181638.md:35:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-p1-160917.md:35:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh423-p1-181824.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,test/gh423-roadmap-render.sh,test/baselines/GH-423-negative-control.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-app.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh351-manifest-unship.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh39-releases-project-sync.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh423-p1-181824.md:145:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-181824.md:183:swept file: yes
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:493:| GH-91 · a build turn has nowhere to write verification output | ✅ | [GH-91-RELAY-SCRATCH-DIR.md](PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md) · [#91](https://github.com/HiQS-Labs/XYZ-forge/issues/91) |
./relay-system/2026-09-07/gh474-md-views-101147/gh474-md-views.codex.md:635:| 65 | **255** | [GH-91](https://github.com/HiQS-Labs/XYZ-forge/issues/91) — a build turn has nowhere to write verification output | — | Completed | 60 | 65 | 55 | 75 | 255 | — |
./relay-system/2026-09-08/marathon-gh492-p1-074252.md:84:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,utils/pdda/pdda.sh,test/gh492-roadmap-state-sweep.sh,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh165-governance-canonical-paths-guard.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh284-p3-release-milestone.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-app.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh35-test-tiers.sh,test/gh351-manifest-unship.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh365-pdda-gov-scan.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh39-releases-project-sync.sh,test/gh414-comment-reference-check.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh544-pre-push-gate.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/hq-hardening.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/jog-queue.sh,test/pdda-local-checks.sh,test/pdda-repo-contract.sh,test/pdda-roadmap-coverage.sh,test/sentinel-overlay.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh492-p1-074252.md:121:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-184859.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,test/gh423-roadmap-render.sh,test/baselines/GH-423-negative-control.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-app.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh351-manifest-unship.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh39-releases-project-sync.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh423-p1-184859.md:145:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-184859.md:183:swept file: yes
./relay-system/2026-09-08/marathon-gh418-p1-212519.md:84:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/marathon_plan.py,utils/py/_marathon_plan.py,test/gh418-planner-ledger-source.sh,test/baselines/GH-418-negative-control.md. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh418-p1-212519.md:123:swept file: yes
./relay-system/2026-09-08/marathon-gh425-p1-221646.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/wave_reconcile.py,test/gh425-gate-provenance-pr.sh,test/baselines/GH-425-negative-control.md. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh425-p1-221646.md:150:swept file: yes
./relay-system/2026-09-08/marathon-gh425-p1-221646.md:198:swept file: yes
./relay-system/2026-09-08/marathon-gh425-p1-221646.md:243:swept file: yes
./relay-system/2026-09-07/gh483-html-removal-115703/gh483-html-removal.codex.md:240:relay-system/2026-08-23/salvage-location-214521/salvage-location.codex.md:1214:./LEADERBOARD.html:375:<script id="ledger-data" type="application/json">{"meta": {"title": "Planning ledgers", "subtitle": "XYZ-forge · releases.db · read-only", "generatedAtDisplay": "2026-08-24 03:30:06Z", "sourceLabel": "releases.db · schema v5", "repoUrl": "https://github.com/HiQS-Suite/XYZ-forge"}, "sync": null, "telemetry": {"dbGeneration": 114, "receipts": 128, "lastSyncDisplay": "2026-08-24T03:30", "lastSyncAgoDisplay": "in 1 day", "releasesOpen": 6, "releasesTotal": 12, "releasesOverdue": 0}, "ratedTasks": [{"id": "GH-67", "title": "Commandcode builder default widened to `--yolo` — closer evaluation → possible build", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 88, "sev": 80, "appeal": 45, "effort": 70, "calc": 283, "effectiveScore": 340}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/67"}, "override": {"value": 340, "hot": true}}, {"id": "GH-181", "title": "repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 90, "sev": 75, "appeal": 90, "effort": 60, "calc": 315, "effectiveScore": 315}, "links": null}, {"id": "GH-174", "title": "Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 85, "sev": 75, "appeal": 95, "effort": 45, "calc": 300, "effectiveScore": 300}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/174"}}, {"id": "GH-155", "title": "3rd Gen ATE & Fuzzing", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 70, "appeal": 90, "effort": 50, "calc": 295, "effectiveScore": 295}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/155"}}, {"id": "GH-165", "title": "Post-Merge Wave & Marathon Lifecycle Reconciler (Docs, ROADMAP, DB, Views, and Planning)", "release": null, "lane": "Completed", "metrics": {"pri": 90, "sev": 80, "appeal": 90, "effort": 35, "calc": 295, "effectiveScore": 295}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/165"}}, {"id": "GH-113", "title": "headless agy builder writes root scratch files, tripping containment (exit 6)", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 85, "sev": 60, "appeal": 85, "effort": 60, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/113"}}, {"id": "GH-148", "title": "DeepSeek Harness (dsh) integration & deepseek-turn shim for OpenRouter DeepSeek V4 Pro", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 75, "appeal": 90, "effort": 40, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/148"}}, {"id": "GH-168", "title": "wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 70, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/168"}}, {"id": "GH-141", "title": "make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison", "release": "Bulkhead", "lane": "ad-hoc detour", "metrics": {"pri": 80, "sev": 65, "appeal": 85, "effort": 55, "calc": 285, "effectiveScore": 285}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/141"}}, {"id": "GH-114", "title": "headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 60, "appeal": 80, "effort": 60, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/114"}}, {"id": "GH-115", "title": "marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 75, "sev": 50, "appeal": 85, "effort": 70, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/115"}}, {"id": "GH-180", "title": "repro_builder crashes on timeout telemetry records (exit_code: null → TypeError)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 70, "sev": 45, "appeal": 85, "effort": 80, "calc": 280, "effectiveScore": 280}, "links": null}, {"id": "GH-77", "title": "`/standup` — session-scoped triage: what did I leave open, what is rotting, is the plan still right?", "release": null, "lane": "Completed", "metrics": {"pri": 95, "sev": 70, "appeal": 85, "effort": 30, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/77"}}, {"id": "GH-124", "title": "eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 60, "appeal": 90, "effort": 40, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/124"}}, {"id": "GH-132", "title": "feat(skills): formal /review-xyz code review skill & multi-model harness", "release": null, "lane": "Completed", "metrics": {"pri": 80, "sev": 70, "appeal": 85, "effort": 40, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/132"}}, {"id": "GH-170", "title": "Agent2Agent: close transcript glitches and harden publishing", "release": null, "lane": "Completed", "metrics": {"pri": 75, "sev": 60, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/170"}}, {"id": "GH-2", "title": "test-suite run relocated an untracked file into .tick/orphan-backups/", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/2"}}, {"id": "GH-8", "title": "kernel boundary hardening — CLI numeric validation, task/agent format contract", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 65, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/8"}}, {"id": "GH-184", "title": "committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 60, "sev": 40, "appeal": 80, "effort": 90, "calc": 270, "effectiveScore": 270}, "links": null}, {"id": "GH-75", "title": "single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 90, "sev": 40, "appeal": 85, "effort": 55, "calc": 270, "effectiveScore": 270}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/75"}}, {"id": "GH-111", "title": "retire manifest FREEZE; tasks and marathons are DIALED IN to exactly one release, as a database state", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 75, "appeal": 70, "effort": 35, "calc": 265, "effectiveScore": 265}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/111"}}, {"id": "GH-182", "title": "self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 55, "calc": 265, "effectiveScore": 265}, "links": null}, {"id": "GH-50", "title": "sandboxed git --track / branch -D half-applies and loses uncommitted work", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 65, "sev": 35, "appeal": 85, "effort": 80, "calc": 265, "effectiveScore": 265}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/50"}}, {"id": "GH-183", "title": "active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 65, "sev": 50, "appeal": 75, "effort": 70, "calc": 260, "effectiveScore": 260}, "links": null}, {"id": "GH-10", "title": "prevent-half of containment: require_fixture adoption across the fixture-creating suites + adoption guard + ci-local identity bracket", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 70, "appeal": 50, "effort": 80, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/10"}}, {"id": "GH-144", "title": "Agent2Agent 3+ participant onboarding + read-only status quick wins", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 30, "appeal": 80, "effort": 90, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/144"}}, {"id": "GH-91", "title": "a build turn has nowhere to write verification output — containment kills a complete, green turn", "release": null, "lane": "Completed", "metrics": {"pri": 60, "sev": 65, "appeal": 55, "effort": 75, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/91"}}, {"id": "GH-153", "title": "RELEASES dashboard sidebar + full-cycle rollup (technical spike)", "release": null, "lane": "Completed", "metrics": {"pri": 70, "sev": 55, "appeal": 80, "effort": 45, "calc": 250, "effectiveScore": 250}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/153"}}, {"id": "GH-197", "title": "two-tier xyz-vendor.sh: Tier 1 core-harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP (GH-105 follow-up)", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 80, "sev": 55, "appeal": 65, "effort": 50, "calc": 250, "effectiveScore": 250}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/197"}}, {"id": "GH-108", "title": "pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)", "release": "Daybreak", "lane": "cut", "metrics": {"pri": 80, "sev": 50, "appeal": 75, "effort": 40, "calc": 245, "effectiveScore": 245}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/108"}}, {"id": "GH-105", "title": "vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)", "release": "Cargo", "lane": "queue", "metrics": {"pri": 75, "sev": 50, "appeal": 60, "effort": 45, "calc": 230, "effectiveScore": 230}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/105"}}, {"id": "GH-32", "title": "RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 70, "sev": 50, "appeal": 65, "effort": 35, "calc": 220, "effectiveScore": 220}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/32"}}, {"id": "GH-5", "title": "kernel robustness: node:test unit runner", "release": "Bulkhead", "lane": "ad-hoc detour", "metrics": {"pri": 45, "sev": 40, "appeal": 45, "effort": 80, "calc": 210, "effectiveScore": 210}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/5"}}, {"id": "GH-35", "title": "3-tier test suite selection (docs / utility subsystems / core) + CPU governance", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 45, "appeal": 50, "effort": 45, "calc": 195, "effectiveScore": 195}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/35"}}, {"id": "GH-61", "title": "RELEASES ledger durability hardening (GH-57 follow-up)", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 45, "sev": 55, "appeal": 40, "effort": 50, "calc": 190, "effectiveScore": 190}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/62"}}, {"id": "GH-17", "title": "SOP for evaluating new agent harnesses and frontier models", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 45, "sev": 30, "appeal": 50, "effort": 60, "calc": 185, "effectiveScore": 185}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/17"}}, {"id": "GH-42", "title": "relay automation: supported Commandcode turn-taker", "release": null, "lane": "Completed", "metrics": {"pri": 50, "sev": 35, "appeal": 55, "effort": 45, "calc": 185, "effectiveScore": 185}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/42"}}, {"id": "GH-195", "title": "marathon-root-audit's blind spot: a direct `python3 marathon_drive.py` call", "release": null, "lane": "Completed", "metrics": {"pri": 60, "sev": 40, "appeal": 50, "effort": 20, "calc": 170, "effectiveScore": 170}, "links": null}, {"id": "GH-28", "title": "RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 40, "sev": 35, "appeal": 40, "effort": 55, "calc": 170, "effectiveScore": 170}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/28"}}, {"id": "GH-18", "title": "Harness evaluation: Command Code (cmd) and model matrix", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 35, "sev": 25, "appeal": 45, "effort": 55, "calc": 160, "effectiveScore": 160}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/18"}}], "justFinished": {"issue": "v0.7.2", "title": "Daybreak shipped", "closedDateDisplay": "2026-08-23", "closedAgoDisplay": "today", "issueUrl": "https://github.com/HiQS-Suite/XYZ-forge/issues/77"}, "whatsNext": {"issue": "v0.7.3", "title": "Bulkhead", "note": "target 2026-09-05 · in 13 days", "issueUrl": "https://github.com/HiQS-Suite/XYZ-forge/issues/179"}, "releases": [{"id": "c-0-1-0", "slug": "quicksilver", "name": "Quicksilver", "version": "0.1.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-01", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Quicksilver", "blurb": "Python-authoritative Tier-A twins.", "exit": "Python-authoritative Tier-A twins. Licensed AGPL-3.0-only (`LICENSE`) with a commercial option (`LICENSE-COMMERCIAL.md`), adopted 2026-07-29 post-ship; the pre-existing conflicting `LICENSE.md` was removed 2026-07-30 (#372).", "detours": [], "roadmap": []}, {"id": "c-0-2-0", "slug": "litmus", "name": "Litmus", "version": "0.2.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-14", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Litmus", "blurb": "Make the checks capable of failing.", "exit": "Exit: `bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what \"done\" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.", "detours": [], "roadmap": []}, {"id": "c-0-3-0", "slug": "nightwatch", "name": "Nightwatch", "version": "0.3.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-14", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Nightwatch", "blurb": "An unattended marathon against a real target repo survives, records, and recovers.", "exit": "Exit: `bash test/nightwatch-release.sh --release-gate` exits 0. BUILT 2026-08-11 and red by design, exactly as Litmus's was; turning it green is what \"done\" means. It has two halves because a metadata audit cannot answer this release's question. Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B executes the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET. The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render's `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.", "detours": [], "roadmap": []}, {"id": "c-0-7-0", "slug": "ballast", "name": "Ballast", "version": "0.7.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-18", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Ballast", "blurb": "Post-launch hardening: the launched repository holds up under a stranger's first run and an outside contributor's first push.", "exit": "Exit: `bash test/ballast-release.sh --release-gate` exits 0. NOT BUILT — writing it is Ballast's first task, before any member is fixed (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. Half A audits the frozen manifest: each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. Half B EXECUTES the stranger's path rather than auditing it: (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. SHIPPED 2026-08-18. `XYZ_BALLAST_STRANGER_RUNS=10 test/ballast-release.sh --release-gate` executed for real against a fresh disposable clone (`~/xyz-disposable/xyz-stranger-clone`): exit 0. Half A: 4 of 4 manifest members complete (#14, #15, #4, #3 — gate/registration/control/CLOSED-issue all confirmed). Half B: 4 of 4 passing (B1: 10/10 consecutive parallel runs with zero failures; B2a: ungated clone warning in-band; B2b: forced-red push refusal; B3: atomic-append cross-process stress case clean) — GOALPOST MET.", "detours": [], "roadmap": []}, {"id": "c-0-7-1", "slug": "bulwark", "name": "Bulwark", "version": "0.7.1", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-19", "extra": null, "itemsTotal": 3, "itemsOpen": 3, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Bulwark", "blurb": "Patch release on Ballast: the RELEASES ledger survives a git merge.", "exit": "Exit: test/gh32-releases-artifacts.sh, test/gh53-releases-merge-resolve.sh, test/gh54-merged-dump-refusals.sh and releases_app.py check all exit 0, AND this release's own merge into development resolves releases.sql without a hand-edit.", "detours": [], "roadmap": [{"id": "GH-52", "title": "issue GH-52", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/52"}}, {"id": "GH-53", "title": "issue GH-53", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/53"}}, {"id": "GH-54", "title": "issue GH-54", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/54"}}]}, {"id": "c-0-7-2", "slug": "daybreak", "name": "Daybreak", "version": "0.7.2", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-23", "extra": null, "itemsTotal": 9, "itemsOpen": 0, "baseline": {"count": 9, "at": "2026-08-21T04:21:29Z", "source": "backfilled", "growth": 0}, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Daybreak", "blurb": "The /standup skill completes: collect.sh implements the eight bounded lens reads that feed triage.py, and the skill runs end-to-end.", "exit": "Exit: collect.sh --fixture emits all eight lenses; triage.py consumes each without a D5; test/gh77-standup-triage.sh green with per-lens assertions AND a per-lens degradation assertion; the skill runs end-to-end on this repo and its output fits the 15-line cap; validate.sh full gate green.", "detours": [], "roadmap": [{"type": "marathon", "id": "GH-77", "url": "https://github.com/HiQS-Suite/XYZ-forge/issues/77", "title": "Daybreak marathon", "meta": "planned", "state": "run", "cards": [{"id": "GH-79", "title": "issue GH-79", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/79"}}, {"id": "GH-80", "title": "issue GH-80", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/80"}}, {"id": "GH-81", "title": "issue GH-81", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/81"}}, {"id": "GH-82", "title": "issue GH-82", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/82"}}, {"id": "GH-83", "title": "issue GH-83", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/83"}}, {"id": "GH-84", "title": "issue GH-84", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/84"}}, {"id": "GH-85", "title": "issue GH-85", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/85"}}, {"id": "GH-86", "title": "issue GH-86", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/86"}}, {"id": "GH-87", "title": "issue GH-87", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/87"}}]}, {"id": "GH-108", "title": "pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)", "marker": "paused", "section": "deferred", "sectionLabel": "cut", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/108", "doc": "PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md"}, "metrics": {"pri": 80, "sev": 50, "appeal": 75, "effort": 40, "calc": 245, "effectiveScore": 245}}]}, {"id": "c-0-7-3", "slug": "bulkhead", "name": "Bulkhead", "version": "0.7.3", "status": "active", "flags": {"now": true}, "badge": {"type": "active", "label": "active"}, "dateLabel": "target", "date": "2026-09-05", "extra": "in 13 days", "itemsTotal": 13, "itemsOpen": 13, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Bulkhead", "blurb": "An unattended marathon survives its own harness.", "exit": "Exit: Each member suite (gh8, gh2, gh50, gh113, gh114, gh115, gh168) green and registered in validate.sh; full local gate green; manifest 7/7 shipped or explicitly cut.", "detours": [{"id": "GH-141", "title": "make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison", "marker": "wip", "section": "adhoc", "sectionLabel": "ad-hoc detour", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/141"}, "metrics": {"pri": 80, "sev": 65, "appeal": 85, "effort": 55, "calc": 285, "effectiveScore": 285}}, {"id": "GH-5", "title": "kernel robustness: node:test unit runner", "marker": "wip", "section": "adhoc", "sectionLabel": "ad-hoc detour", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/5"}, "metrics": {"pri": 45, "sev": 40, "appeal": 45, "effort": 80, "calc": 210, "effectiveScore": 210}}], "roadmap": [{"id": "GH-113", "title": "headless agy builder writes root scratch files, tripping containment (exit 6)", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/113", "doc": "PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md"}, "metrics": {"pri": 85, "sev": 60, "appeal": 85, "effort": 60, "calc": 290, "effectiveScore": 290}}, {"id": "GH-114", "title": "headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/114", "doc": "PROJECT/2-WORKING/GH-114-HEADLESS-TTY-IDLE-HANG.md"}, "metrics": {"pri": 80, "sev": 60, "appeal": 80, "effort": 60, "calc": 280, "effectiveScore": 280}}, {"id": "GH-115", "title": "marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/115", "doc": "PROJECT/3-COMPLETED/GH-115-ROUND-CAP-ESCALATION.md"}, "metrics": {"pri": 75, "sev": 50, "appeal": 85, "effort": 70, "calc": 280, "effectiveScore": 280}}, {"id": "GH-168", "title": "wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/168", "doc": "PROJECT/2-WORKING/GH-168-WAVE-RECONCILE-SCOPE.md"}, "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 70, "calc": 290, "effectiveScore": 290}}, {"id": "GH-8", "title": "kernel boundary hardening — CLI numeric validation, task/agent format contract", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/8", "doc": "PROJECT/3-COMPLETED/GH-8-KERNEL-BOUNDARY-HARDENING.md"}, "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 65, "calc": 275, "effectiveScore": 275}}, {"id": "GH-2", "title": "test-suite run relocated an untracked file into .tick/orphan-backups/", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/2", "doc": "PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md"}, "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}}, {"id": "GH-50", "title": "sandboxed git --track / branch -D half-applies and loses uncommitted work", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/50", "doc": "PROJECT/2-WORKING/GH-50-SANDBOXED-GIT-HALF-APPLY.md"}, "metrics": {"pri": 65, "sev": 35, "appeal": 85, "effort": 80, "calc": 265, "effectiveScore": 265}}, {"id": "GH-180", "title": "repro_builder crashes on timeout telemetry records (exit_code: null → TypeError)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/180", "doc": "PROJECT/3-COMPLETED/GH-180-REPRO-TIMEOUT-CRASH.md"}, "metrics": {"pri": 70, "sev": 45, "appeal": 85, "effort": 80, "calc": 280, "effectiveScore": 280}}, {"id": "GH-181", "title": "repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/181", "doc": "PROJECT/3-COMPLETED/GH-181-REPRO-ADAPTER-FIDELITY.md"}, "metrics": {"pri": 90, "sev": 75, "appeal": 90, "effort": 60, "calc": 315, "effectiveScore": 315}}, {"id": "GH-182", "title": "self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/182", "doc": "PROJECT/2-WORKING/GH-182-HEALER-FACADE-SAFETY.md"}, "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 55, "calc": 265, "effectiveScore": 265}}, {"id": "GH-183", "title": "active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/183", "doc": "PROJECT/3-COMPLETED/GH-183-EXPLORER-ENV-SOUNDNESS.md"}, "metrics": {"pri": 65, "sev": 50, "appeal": 75, "effort": 70, "calc": 260, "effectiveScore": 260}}, {"id": "GH-184", "title": "committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/184", "doc": "PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md"}, "metrics": {"pri": 60, "sev": 40, "appeal": 80, "effort": 90, "calc": 270, "effectiveScore": 270}}, {"id": "GH-174", "title": "Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/174", "doc": "PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md"}, "metrics": {"pri": 85, "sev": 75, "appeal": 95, "effort": 45, "calc": 300, "effectiveScore": 300}}]}, {"id": "c-0-9-0", "slug": "cargo", "name": "Cargo", "version": "0.9.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-09-19", "extra": "in 27 days", "itemsTotal": 2, "itemsOpen": 2, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Cargo", "blurb": "The harness travels with its ledger: the RELEASES DB system (releases_app.py CLI + merge resolver + FAQs) and the GH-103 HTML timeline generator (utils/timeline/) ship inside every vendored .xyz/ payload as an optional, never-wired-by-default add-on — a 'when you're ready' module a target repo enables by running releases init itself, matching RELEASES.md's own OPTIONAL philosophy (GH-381).", "exit": "Exit: A repo vendored with xyz-vendor.sh can, with zero extra downloads, run releases init/add and export_timeline.py --preview from .xyz/ against its own root, and xyz-sync.sh update preserves the target's ledger state (GH-312 preserve list). Nothing runs until the user invokes it.", "detours": [], "roadmap": [{"id": "GH-105", "title": "vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/105", "doc": "PROJECT/1-INBOX/GH-105-VENDOR-RELEASES-ADDON.md"}, "metrics": {"pri": 75, "sev": 50, "appeal": 60, "effort": 45, "calc": 230, "effectiveScore": 230}}, {"id": "GH-107", "title": "issue GH-107", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/107"}}]}, {"id": "c-0-6-0", "slug": "meter", "name": "Meter", "version": "0.6.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-09-26", "extra": "in 34 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Meter", "blurb": "XYZ can be handed to a stranger: an unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context, from a sanitized, secret-scanned tree.", "exit": "Exit: bash test/meter-release.sh --release-gate exits 0. NOT BUILT — written first, before any sanitization (the Litmus/Nightwatch ordering). Half A AUDITS the launch artifact: single-commit sanitized clone at the declared path; CHANGELOG.md byte-identical; .tick/, relay-system/, temp/ absent; PROJECT/ = PDDA scaffold + retained Meter example only; both LICENSE files present and consistent; secret-scan result names tool version and exact commit. Half B EXECUTES the stranger's path: a credential-less clone of the published commit completes one supported happy path with nothing author-machine-local. Negative control --mutate-evidence: plant a private path, remove CHANGELOG.md, leave a relay-system/ behind — detect all three, re-check unmutated inputs green in the same run. RED on arrival.", "detours": [], "roadmap": []}, {"id": "c-0-8-0", "slug": "sundown", "name": "Sundown", "version": "0.8.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-10-17", "extra": "in 55 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Sundown", "blurb": "Retire the twelve frozen Bash twins.", "exit": "Exit: NOT WRITTEN. Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.", "detours": [], "roadmap": []}, {"id": "c-0-4-0", "slug": "plumbline", "name": "Plumbline", "version": "0.4.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-11-14", "extra": "in 83 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Plumbline", "blurb": "Assisted reflection and a bounded self-improvement loop, measured before either is trusted.", "exit": "Assisted reflection and a bounded self-improvement loop, measured before either is trusted. The reflection pipeline turns durable Nightwatch records into proposals (`proposals-sink.sh` gains its first production caller) and is graded against external ground truth — the 49 human-f…", "detours": [], "roadmap": []}, {"id": "c-0-5-0", "slug": "lantern", "name": "Lantern", "version": "0.5.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-12-12", "extra": "in 111 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "milestones", "blurb": "When the harness fails, the information needed to act already exists inside it — make it say so.", "exit": "Exit: `bash test/lantern-release.sh --release-gate` exits 0. NOT BUILT. Writing it precedes fixing any member, which is the Litmus and Nightwatch ordering and the reason both releases could tell a finished entry from a claimed one. Two halves, the established shape: Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below. Half B executes #499's four phases rather than auditing them, since every one of them is a message an operator either receives or does not: a `relay-drive` launch preflight that refuses before spending, a gate refusal that states its real reason, a launcher exit code that survives its wrapper, and a change-impact report. #358 Phase 2 is the one member with no executable half, and the criterion is written around that rather than pretending otherwise: it is satisfied by a RECORDED transcript of a real CI failure under `test/baselines/`, and it must NOT be satisfiable by a disposition written in advance — that issue's own capture doc forbids pre-committing one, and an exit criterion that accepted a pre-written verdict would launder exactly the thing #419 exists to prevent. Its own negative control is `--mutate-evidence`, which must unregister a gate, delete a recorded control, and substitute a pre-dated disposition for a real transcript — detecting all three, and re-checking the unmutated inputs green in the same run so an always-red detector cannot pass for one.", "detours": [], "roadmap": []}], "projects": [{"slug": "XYZ-forge", "active": true}], "cycle": {"repo": "XYZ-forge", "generatedAt": "2026-08-24T03:30:06Z", "db": {"generation": 114, "receipts": 128, "lastOp": "2026-08-24T03:30:06Z", "schemaVersion": 5}, "releases": {"total": 12, "open": 6, "overdue": 0, "byStatus": {"active": 1, "draft": 5, "shipped": 6}, "openList": [{"version": "0.7.3", "codename": "Bulkhead", "status": "active", "target": "2026-09-05", "daysToTarget": 13}, {"version": "0.9.0", "codename": "Cargo", "status": "draft", "target": "2026-09-19", "daysToTarget": 27}, {"version": "0.6.0", "codename": "Meter", "status": "draft", "target": "2026-09-26", "daysToTarget": 34}, {"version": "0.8.0", "codename": "Sundown", "status": "draft", "target": "2026-10-17", "daysToTarget": 55}, {"version": "0.4.0", "codename": "Plumbline", "status": "draft", "target": "2026-11-14", "daysToTarget": 83}], "recentShipped": [{"version": "0.7.2", "shipped": "2026-08-23"}, {"version": "0.7.1", "shipped": "2026-08-19"}, {"version": "0.7.0", "shipped": "2026-08-18"}]}, "roadmap": {"total": 56, "unmarked": 9, "wip": 9, "queued": 0, "done": 38, "paused": 0}, "marathons": {"total": 1, "byStatus": {"planned": 1}, "runningRefs": ["GH-77"]}, "items": {"open": 0, "dialedIn": 18, "shipped": 9, "cut": 1}, "recentEvents": [{"at": "2026-08-23T04:30:03Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-87"}, {"at": "2026-08-23T04:30:02Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-85"}, {"at": "2026-08-23T04:30:02Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-86"}, {"at": "2026-08-23T04:30:01Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-82"}, {"at": "2026-08-23T04:30:01Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-83"}]}, "view": "leaderboard"}</script>
./relay-system/2026-09-07/gh483-html-removal-115703/gh483-html-removal.codex.md:241:relay-system/2026-08-23/salvage-location-214521/salvage-location.codex.md:1312:./RELEASES-PREVIEW.html:375:<script id="ledger-data" type="application/json">{"meta": {"title": "Planning ledgers", "subtitle": "XYZ-forge · releases.db · read-only", "generatedAtDisplay": "2026-08-24 03:30:06Z", "sourceLabel": "releases.db · schema v5", "repoUrl": "https://github.com/HiQS-Suite/XYZ-forge"}, "sync": null, "telemetry": {"dbGeneration": 114, "receipts": 128, "lastSyncDisplay": "2026-08-24T03:30", "lastSyncAgoDisplay": "in 1 day", "releasesOpen": 6, "releasesTotal": 12, "releasesOverdue": 0}, "ratedTasks": [{"id": "GH-67", "title": "Commandcode builder default widened to `--yolo` — closer evaluation → possible build", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 88, "sev": 80, "appeal": 45, "effort": 70, "calc": 283, "effectiveScore": 340}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/67"}, "override": {"value": 340, "hot": true}}, {"id": "GH-181", "title": "repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 90, "sev": 75, "appeal": 90, "effort": 60, "calc": 315, "effectiveScore": 315}, "links": null}, {"id": "GH-174", "title": "Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 85, "sev": 75, "appeal": 95, "effort": 45, "calc": 300, "effectiveScore": 300}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/174"}}, {"id": "GH-155", "title": "3rd Gen ATE & Fuzzing", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 70, "appeal": 90, "effort": 50, "calc": 295, "effectiveScore": 295}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/155"}}, {"id": "GH-165", "title": "Post-Merge Wave & Marathon Lifecycle Reconciler (Docs, ROADMAP, DB, Views, and Planning)", "release": null, "lane": "Completed", "metrics": {"pri": 90, "sev": 80, "appeal": 90, "effort": 35, "calc": 295, "effectiveScore": 295}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/165"}}, {"id": "GH-113", "title": "headless agy builder writes root scratch files, tripping containment (exit 6)", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 85, "sev": 60, "appeal": 85, "effort": 60, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/113"}}, {"id": "GH-148", "title": "DeepSeek Harness (dsh) integration & deepseek-turn shim for OpenRouter DeepSeek V4 Pro", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 75, "appeal": 90, "effort": 40, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/148"}}, {"id": "GH-168", "title": "wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 70, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/168"}}, {"id": "GH-141", "title": "make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison", "release": "Bulkhead", "lane": "ad-hoc detour", "metrics": {"pri": 80, "sev": 65, "appeal": 85, "effort": 55, "calc": 285, "effectiveScore": 285}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/141"}}, {"id": "GH-114", "title": "headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 60, "appeal": 80, "effort": 60, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/114"}}, {"id": "GH-115", "title": "marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 75, "sev": 50, "appeal": 85, "effort": 70, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/115"}}, {"id": "GH-180", "title": "repro_builder crashes on timeout telemetry records (exit_code: null → TypeError)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 70, "sev": 45, "appeal": 85, "effort": 80, "calc": 280, "effectiveScore": 280}, "links": null}, {"id": "GH-77", "title": "`/standup` — session-scoped triage: what did I leave open, what is rotting, is the plan still right?", "release": null, "lane": "Completed", "metrics": {"pri": 95, "sev": 70, "appeal": 85, "effort": 30, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/77"}}, {"id": "GH-124", "title": "eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 60, "appeal": 90, "effort": 40, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/124"}}, {"id": "GH-132", "title": "feat(skills): formal /review-xyz code review skill & multi-model harness", "release": null, "lane": "Completed", "metrics": {"pri": 80, "sev": 70, "appeal": 85, "effort": 40, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/132"}}, {"id": "GH-170", "title": "Agent2Agent: close transcript glitches and harden publishing", "release": null, "lane": "Completed", "metrics": {"pri": 75, "sev": 60, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/170"}}, {"id": "GH-2", "title": "test-suite run relocated an untracked file into .tick/orphan-backups/", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/2"}}, {"id": "GH-8", "title": "kernel boundary hardening — CLI numeric validation, task/agent format contract", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 65, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/8"}}, {"id": "GH-184", "title": "committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 60, "sev": 40, "appeal": 80, "effort": 90, "calc": 270, "effectiveScore": 270}, "links": null}, {"id": "GH-75", "title": "single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 90, "sev": 40, "appeal": 85, "effort": 55, "calc": 270, "effectiveScore": 270}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/75"}}, {"id": "GH-111", "title": "retire manifest FREEZE; tasks and marathons are DIALED IN to exactly one release, as a database state", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 75, "appeal": 70, "effort": 35, "calc": 265, "effectiveScore": 265}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/111"}}, {"id": "GH-182", "title": "self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 55, "calc": 265, "effectiveScore": 265}, "links": null}, {"id": "GH-50", "title": "sandboxed git --track / branch -D half-applies and loses uncommitted work", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 65, "sev": 35, "appeal": 85, "effort": 80, "calc": 265, "effectiveScore": 265}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/50"}}, {"id": "GH-183", "title": "active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 65, "sev": 50, "appeal": 75, "effort": 70, "calc": 260, "effectiveScore": 260}, "links": null}, {"id": "GH-10", "title": "prevent-half of containment: require_fixture adoption across the fixture-creating suites + adoption guard + ci-local identity bracket", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 70, "appeal": 50, "effort": 80, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/10"}}, {"id": "GH-144", "title": "Agent2Agent 3+ participant onboarding + read-only status quick wins", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 30, "appeal": 80, "effort": 90, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/144"}}, {"id": "GH-91", "title": "a build turn has nowhere to write verification output — containment kills a complete, green turn", "release": null, "lane": "Completed", "metrics": {"pri": 60, "sev": 65, "appeal": 55, "effort": 75, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/91"}}, {"id": "GH-153", "title": "RELEASES dashboard sidebar + full-cycle rollup (technical spike)", "release": null, "lane": "Completed", "metrics": {"pri": 70, "sev": 55, "appeal": 80, "effort": 45, "calc": 250, "effectiveScore": 250}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/153"}}, {"id": "GH-197", "title": "two-tier xyz-vendor.sh: Tier 1 core-harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP (GH-105 follow-up)", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 80, "sev": 55, "appeal": 65, "effort": 50, "calc": 250, "effectiveScore": 250}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/197"}}, {"id": "GH-108", "title": "pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)", "release": "Daybreak", "lane": "cut", "metrics": {"pri": 80, "sev": 50, "appeal": 75, "effort": 40, "calc": 245, "effectiveScore": 245}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/108"}}, {"id": "GH-105", "title": "vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)", "release": "Cargo", "lane": "queue", "metrics": {"pri": 75, "sev": 50, "appeal": 60, "effort": 45, "calc": 230, "effectiveScore": 230}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/105"}}, {"id": "GH-32", "title": "RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 70, "sev": 50, "appeal": 65, "effort": 35, "calc": 220, "effectiveScore": 220}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/32"}}, {"id": "GH-5", "title": "kernel robustness: node:test unit runner", "release": "Bulkhead", "lane": "ad-hoc detour", "metrics": {"pri": 45, "sev": 40, "appeal": 45, "effort": 80, "calc": 210, "effectiveScore": 210}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/5"}}, {"id": "GH-35", "title": "3-tier test suite selection (docs / utility subsystems / core) + CPU governance", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 45, "appeal": 50, "effort": 45, "calc": 195, "effectiveScore": 195}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/35"}}, {"id": "GH-61", "title": "RELEASES ledger durability hardening (GH-57 follow-up)", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 45, "sev": 55, "appeal": 40, "effort": 50, "calc": 190, "effectiveScore": 190}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/62"}}, {"id": "GH-17", "title": "SOP for evaluating new agent harnesses and frontier models", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 45, "sev": 30, "appeal": 50, "effort": 60, "calc": 185, "effectiveScore": 185}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/17"}}, {"id": "GH-42", "title": "relay automation: supported Commandcode turn-taker", "release": null, "lane": "Completed", "metrics": {"pri": 50, "sev": 35, "appeal": 55, "effort": 45, "calc": 185, "effectiveScore": 185}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/42"}}, {"id": "GH-195", "title": "marathon-root-audit's blind spot: a direct `python3 marathon_drive.py` call", "release": null, "lane": "Completed", "metrics": {"pri": 60, "sev": 40, "appeal": 50, "effort": 20, "calc": 170, "effectiveScore": 170}, "links": null}, {"id": "GH-28", "title": "RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 40, "sev": 35, "appeal": 40, "effort": 55, "calc": 170, "effectiveScore": 170}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/28"}}, {"id": "GH-18", "title": "Harness evaluation: Command Code (cmd) and model matrix", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 35, "sev": 25, "appeal": 45, "effort": 55, "calc": 160, "effectiveScore": 160}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/18"}}], "justFinished": {"issue": "v0.7.2", "title": "Daybreak shipped", "closedDateDisplay": "2026-08-23", "closedAgoDisplay": "today", "issueUrl": "https://github.com/HiQS-Suite/XYZ-forge/issues/77"}, "whatsNext": {"issue": "v0.7.3", "title": "Bulkhead", "note": "target 2026-09-05 · in 13 days", "issueUrl": "https://github.com/HiQS-Suite/XYZ-forge/issues/179"}, "releases": [{"id": "c-0-1-0", "slug": "quicksilver", "name": "Quicksilver", "version": "0.1.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-01", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Quicksilver", "blurb": "Python-authoritative Tier-A twins.", "exit": "Python-authoritative Tier-A twins. Licensed AGPL-3.0-only (`LICENSE`) with a commercial option (`LICENSE-COMMERCIAL.md`), adopted 2026-07-29 post-ship; the pre-existing conflicting `LICENSE.md` was removed 2026-07-30 (#372).", "detours": [], "roadmap": []}, {"id": "c-0-2-0", "slug": "litmus", "name": "Litmus", "version": "0.2.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-14", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Litmus", "blurb": "Make the checks capable of failing.", "exit": "Exit: `bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what \"done\" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.", "detours": [], "roadmap": []}, {"id": "c-0-3-0", "slug": "nightwatch", "name": "Nightwatch", "version": "0.3.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-14", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Nightwatch", "blurb": "An unattended marathon against a real target repo survives, records, and recovers.", "exit": "Exit: `bash test/nightwatch-release.sh --release-gate` exits 0. BUILT 2026-08-11 and red by design, exactly as Litmus's was; turning it green is what \"done\" means. It has two halves because a metadata audit cannot answer this release's question. Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B executes the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET. The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render's `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.", "detours": [], "roadmap": []}, {"id": "c-0-7-0", "slug": "ballast", "name": "Ballast", "version": "0.7.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-18", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Ballast", "blurb": "Post-launch hardening: the launched repository holds up under a stranger's first run and an outside contributor's first push.", "exit": "Exit: `bash test/ballast-release.sh --release-gate` exits 0. NOT BUILT — writing it is Ballast's first task, before any member is fixed (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. Half A audits the frozen manifest: each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. Half B EXECUTES the stranger's path rather than auditing it: (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. SHIPPED 2026-08-18. `XYZ_BALLAST_STRANGER_RUNS=10 test/ballast-release.sh --release-gate` executed for real against a fresh disposable clone (`~/xyz-disposable/xyz-stranger-clone`): exit 0. Half A: 4 of 4 manifest members complete (#14, #15, #4, #3 — gate/registration/control/CLOSED-issue all confirmed). Half B: 4 of 4 passing (B1: 10/10 consecutive parallel runs with zero failures; B2a: ungated clone warning in-band; B2b: forced-red push refusal; B3: atomic-append cross-process stress case clean) — GOALPOST MET.", "detours": [], "roadmap": []}, {"id": "c-0-7-1", "slug": "bulwark", "name": "Bulwark", "version": "0.7.1", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-19", "extra": null, "itemsTotal": 3, "itemsOpen": 3, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Bulwark", "blurb": "Patch release on Ballast: the RELEASES ledger survives a git merge.", "exit": "Exit: test/gh32-releases-artifacts.sh, test/gh53-releases-merge-resolve.sh, test/gh54-merged-dump-refusals.sh and releases_app.py check all exit 0, AND this release's own merge into development resolves releases.sql without a hand-edit.", "detours": [], "roadmap": [{"id": "GH-52", "title": "issue GH-52", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/52"}}, {"id": "GH-53", "title": "issue GH-53", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/53"}}, {"id": "GH-54", "title": "issue GH-54", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/54"}}]}, {"id": "c-0-7-2", "slug": "daybreak", "name": "Daybreak", "version": "0.7.2", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-23", "extra": null, "itemsTotal": 9, "itemsOpen": 0, "baseline": {"count": 9, "at": "2026-08-21T04:21:29Z", "source": "backfilled", "growth": 0}, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Daybreak", "blurb": "The /standup skill completes: collect.sh implements the eight bounded lens reads that feed triage.py, and the skill runs end-to-end.", "exit": "Exit: collect.sh --fixture emits all eight lenses; triage.py consumes each without a D5; test/gh77-standup-triage.sh green with per-lens assertions AND a per-lens degradation assertion; the skill runs end-to-end on this repo and its output fits the 15-line cap; validate.sh full gate green.", "detours": [], "roadmap": [{"type": "marathon", "id": "GH-77", "url": "https://github.com/HiQS-Suite/XYZ-forge/issues/77", "title": "Daybreak marathon", "meta": "planned", "state": "run", "cards": [{"id": "GH-79", "title": "issue GH-79", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/79"}}, {"id": "GH-80", "title": "issue GH-80", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/80"}}, {"id": "GH-81", "title": "issue GH-81", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/81"}}, {"id": "GH-82", "title": "issue GH-82", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/82"}}, {"id": "GH-83", "title": "issue GH-83", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/83"}}, {"id": "GH-84", "title": "issue GH-84", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/84"}}, {"id": "GH-85", "title": "issue GH-85", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/85"}}, {"id": "GH-86", "title": "issue GH-86", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/86"}}, {"id": "GH-87", "title": "issue GH-87", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/87"}}]}, {"id": "GH-108", "title": "pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)", "marker": "paused", "section": "deferred", "sectionLabel": "cut", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/108", "doc": "PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md"}, "metrics": {"pri": 80, "sev": 50, "appeal": 75, "effort": 40, "calc": 245, "effectiveScore": 245}}]}, {"id": "c-0-7-3", "slug": "bulkhead", "name": "Bulkhead", "version": "0.7.3", "status": "active", "flags": {"now": true}, "badge": {"type": "active", "label": "active"}, "dateLabel": "target", "date": "2026-09-05", "extra": "in 13 days", "itemsTotal": 13, "itemsOpen": 13, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Bulkhead", "blurb": "An unattended marathon survives its own harness.", "exit": "Exit: Each member suite (gh8, gh2, gh50, gh113, gh114, gh115, gh168) green and registered in validate.sh; full local gate green; manifest 7/7 shipped or explicitly cut.", "detours": [{"id": "GH-141", "title": "make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison", "marker": "wip", "section": "adhoc", "sectionLabel": "ad-hoc detour", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/141"}, "metrics": {"pri": 80, "sev": 65, "appeal": 85, "effort": 55, "calc": 285, "effectiveScore": 285}}, {"id": "GH-5", "title": "kernel robustness: node:test unit runner", "marker": "wip", "section": "adhoc", "sectionLabel": "ad-hoc detour", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/5"}, "metrics": {"pri": 45, "sev": 40, "appeal": 45, "effort": 80, "calc": 210, "effectiveScore": 210}}], "roadmap": [{"id": "GH-113", "title": "headless agy builder writes root scratch files, tripping containment (exit 6)", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/113", "doc": "PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md"}, "metrics": {"pri": 85, "sev": 60, "appeal": 85, "effort": 60, "calc": 290, "effectiveScore": 290}}, {"id": "GH-114", "title": "headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/114", "doc": "PROJECT/2-WORKING/GH-114-HEADLESS-TTY-IDLE-HANG.md"}, "metrics": {"pri": 80, "sev": 60, "appeal": 80, "effort": 60, "calc": 280, "effectiveScore": 280}}, {"id": "GH-115", "title": "marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/115", "doc": "PROJECT/3-COMPLETED/GH-115-ROUND-CAP-ESCALATION.md"}, "metrics": {"pri": 75, "sev": 50, "appeal": 85, "effort": 70, "calc": 280, "effectiveScore": 280}}, {"id": "GH-168", "title": "wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/168", "doc": "PROJECT/2-WORKING/GH-168-WAVE-RECONCILE-SCOPE.md"}, "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 70, "calc": 290, "effectiveScore": 290}}, {"id": "GH-8", "title": "kernel boundary hardening — CLI numeric validation, task/agent format contract", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/8", "doc": "PROJECT/3-COMPLETED/GH-8-KERNEL-BOUNDARY-HARDENING.md"}, "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 65, "calc": 275, "effectiveScore": 275}}, {"id": "GH-2", "title": "test-suite run relocated an untracked file into .tick/orphan-backups/", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/2", "doc": "PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md"}, "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}}, {"id": "GH-50", "title": "sandboxed git --track / branch -D half-applies and loses uncommitted work", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/50", "doc": "PROJECT/2-WORKING/GH-50-SANDBOXED-GIT-HALF-APPLY.md"}, "metrics": {"pri": 65, "sev": 35, "appeal": 85, "effort": 80, "calc": 265, "effectiveScore": 265}}, {"id": "GH-180", "title": "repro_builder crashes on timeout telemetry records (exit_code: null → TypeError)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/180", "doc": "PROJECT/3-COMPLETED/GH-180-REPRO-TIMEOUT-CRASH.md"}, "metrics": {"pri": 70, "sev": 45, "appeal": 85, "effort": 80, "calc": 280, "effectiveScore": 280}}, {"id": "GH-181", "title": "repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/181", "doc": "PROJECT/3-COMPLETED/GH-181-REPRO-ADAPTER-FIDELITY.md"}, "metrics": {"pri": 90, "sev": 75, "appeal": 90, "effort": 60, "calc": 315, "effectiveScore": 315}}, {"id": "GH-182", "title": "self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/182", "doc": "PROJECT/2-WORKING/GH-182-HEALER-FACADE-SAFETY.md"}, "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 55, "calc": 265, "effectiveScore": 265}}, {"id": "GH-183", "title": "active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/183", "doc": "PROJECT/3-COMPLETED/GH-183-EXPLORER-ENV-SOUNDNESS.md"}, "metrics": {"pri": 65, "sev": 50, "appeal": 75, "effort": 70, "calc": 260, "effectiveScore": 260}}, {"id": "GH-184", "title": "committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/184", "doc": "PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md"}, "metrics": {"pri": 60, "sev": 40, "appeal": 80, "effort": 90, "calc": 270, "effectiveScore": 270}}, {"id": "GH-174", "title": "Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/174", "doc": "PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md"}, "metrics": {"pri": 85, "sev": 75, "appeal": 95, "effort": 45, "calc": 300, "effectiveScore": 300}}]}, {"id": "c-0-9-0", "slug": "cargo", "name": "Cargo", "version": "0.9.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-09-19", "extra": "in 27 days", "itemsTotal": 2, "itemsOpen": 2, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Cargo", "blurb": "The harness travels with its ledger: the RELEASES DB system (releases_app.py CLI + merge resolver + FAQs) and the GH-103 HTML timeline generator (utils/timeline/) ship inside every vendored .xyz/ payload as an optional, never-wired-by-default add-on — a 'when you're ready' module a target repo enables by running releases init itself, matching RELEASES.md's own OPTIONAL philosophy (GH-381).", "exit": "Exit: A repo vendored with xyz-vendor.sh can, with zero extra downloads, run releases init/add and export_timeline.py --preview from .xyz/ against its own root, and xyz-sync.sh update preserves the target's ledger state (GH-312 preserve list). Nothing runs until the user invokes it.", "detours": [], "roadmap": [{"id": "GH-105", "title": "vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/105", "doc": "PROJECT/1-INBOX/GH-105-VENDOR-RELEASES-ADDON.md"}, "metrics": {"pri": 75, "sev": 50, "appeal": 60, "effort": 45, "calc": 230, "effectiveScore": 230}}, {"id": "GH-107", "title": "issue GH-107", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/107"}}]}, {"id": "c-0-6-0", "slug": "meter", "name": "Meter", "version": "0.6.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-09-26", "extra": "in 34 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Meter", "blurb": "XYZ can be handed to a stranger: an unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context, from a sanitized, secret-scanned tree.", "exit": "Exit: bash test/meter-release.sh --release-gate exits 0. NOT BUILT — written first, before any sanitization (the Litmus/Nightwatch ordering). Half A AUDITS the launch artifact: single-commit sanitized clone at the declared path; CHANGELOG.md byte-identical; .tick/, relay-system/, temp/ absent; PROJECT/ = PDDA scaffold + retained Meter example only; both LICENSE files present and consistent; secret-scan result names tool version and exact commit. Half B EXECUTES the stranger's path: a credential-less clone of the published commit completes one supported happy path with nothing author-machine-local. Negative control --mutate-evidence: plant a private path, remove CHANGELOG.md, leave a relay-system/ behind — detect all three, re-check unmutated inputs green in the same run. RED on arrival.", "detours": [], "roadmap": []}, {"id": "c-0-8-0", "slug": "sundown", "name": "Sundown", "version": "0.8.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-10-17", "extra": "in 55 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Sundown", "blurb": "Retire the twelve frozen Bash twins.", "exit": "Exit: NOT WRITTEN. Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.", "detours": [], "roadmap": []}, {"id": "c-0-4-0", "slug": "plumbline", "name": "Plumbline", "version": "0.4.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-11-14", "extra": "in 83 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Plumbline", "blurb": "Assisted reflection and a bounded self-improvement loop, measured before either is trusted.", "exit": "Assisted reflection and a bounded self-improvement loop, measured before either is trusted. The reflection pipeline turns durable Nightwatch records into proposals (`proposals-sink.sh` gains its first production caller) and is graded against external ground truth — the 49 human-f…", "detours": [], "roadmap": []}, {"id": "c-0-5-0", "slug": "lantern", "name": "Lantern", "version": "0.5.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-12-12", "extra": "in 111 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "milestones", "blurb": "When the harness fails, the information needed to act already exists inside it — make it say so.", "exit": "Exit: `bash test/lantern-release.sh --release-gate` exits 0. NOT BUILT. Writing it precedes fixing any member, which is the Litmus and Nightwatch ordering and the reason both releases could tell a finished entry from a claimed one. Two halves, the established shape: Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below. Half B executes #499's four phases rather than auditing them, since every one of them is a message an operator either receives or does not: a `relay-drive` launch preflight that refuses before spending, a gate refusal that states its real reason, a launcher exit code that survives its wrapper, and a change-impact report. #358 Phase 2 is the one member with no executable half, and the criterion is written around that rather than pretending otherwise: it is satisfied by a RECORDED transcript of a real CI failure under `test/baselines/`, and it must NOT be satisfiable by a disposition written in advance — that issue's own capture doc forbids pre-committing one, and an exit criterion that accepted a pre-written verdict would launder exactly the thing #419 exists to prevent. Its own negative control is `--mutate-evidence`, which must unregister a gate, delete a recorded control, and substitute a pre-dated disposition for a real transcript — detecting all three, and re-checking the unmutated inputs green in the same run so an always-red detector cannot pass for one.", "detours": [], "roadmap": []}], "projects": [{"slug": "XYZ-forge", "active": true}], "cycle": {"repo": "XYZ-forge", "generatedAt": "2026-08-24T03:30:06Z", "db": {"generation": 114, "receipts": 128, "lastOp": "2026-08-24T03:30:06Z", "schemaVersion": 5}, "releases": {"total": 12, "open": 6, "overdue": 0, "byStatus": {"active": 1, "draft": 5, "shipped": 6}, "openList": [{"version": "0.7.3", "codename": "Bulkhead", "status": "active", "target": "2026-09-05", "daysToTarget": 13}, {"version": "0.9.0", "codename": "Cargo", "status": "draft", "target": "2026-09-19", "daysToTarget": 27}, {"version": "0.6.0", "codename": "Meter", "status": "draft", "target": "2026-09-26", "daysToTarget": 34}, {"version": "0.8.0", "codename": "Sundown", "status": "draft", "target": "2026-10-17", "daysToTarget": 55}, {"version": "0.4.0", "codename": "Plumbline", "status": "draft", "target": "2026-11-14", "daysToTarget": 83}], "recentShipped": [{"version": "0.7.2", "shipped": "2026-08-23"}, {"version": "0.7.1", "shipped": "2026-08-19"}, {"version": "0.7.0", "shipped": "2026-08-18"}]}, "roadmap": {"total": 56, "unmarked": 9, "wip": 9, "queued": 0, "done": 38, "paused": 0}, "marathons": {"total": 1, "byStatus": {"planned": 1}, "runningRefs": ["GH-77"]}, "items": {"open": 0, "dialedIn": 18, "shipped": 9, "cut": 1}, "recentEvents": [{"at": "2026-08-23T04:30:03Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-87"}, {"at": "2026-08-23T04:30:02Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-85"}, {"at": "2026-08-23T04:30:02Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-86"}, {"at": "2026-08-23T04:30:01Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-82"}, {"at": "2026-08-23T04:30:01Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-83"}]}}</script>
./relay-system/2026-09-08/marathon-gh423-p1-192457.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,test/gh423-roadmap-render.sh,test/baselines/GH-423-negative-control.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-app.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh351-manifest-unship.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh39-releases-project-sync.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh423-p1-192457.md:145:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-192457.md:183:swept file: yes
./relay-system/2026-09-08/marathon-gh492-p1-073058.md:84:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,utils/pdda/pdda.sh,test/gh492-roadmap-state-sweep.sh,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh165-governance-canonical-paths-guard.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh284-p3-release-milestone.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-app.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh35-test-tiers.sh,test/gh351-manifest-unship.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh365-pdda-gov-scan.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh39-releases-project-sync.sh,test/gh414-comment-reference-check.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh544-pre-push-gate.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/hq-hardening.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/jog-queue.sh,test/pdda-local-checks.sh,test/pdda-repo-contract.sh,test/pdda-roadmap-coverage.sh,test/sentinel-overlay.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh492-p1-073058.md:121:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-181737.md:80:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,test/gh423-roadmap-render.sh,test/baselines/GH-423-negative-control.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh269-roadmap-retired.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-app.sh,test/gh32-releases-artifacts.sh,test/gh349-releases-roadmap-vendored.sh,test/gh351-manifest-unship.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh360-dump-multiline-values.sh,test/gh360-scoped-receipt-chain-rebuild.sh,test/gh39-releases-project-sync.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./relay-system/2026-09-08/marathon-gh423-p1-181737.md:145:swept file: yes
./relay-system/2026-09-08/marathon-gh423-p1-181737.md:183:swept file: yes
./relay-system/2026-09-08/marathon-p1-174300.md:35:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/feature.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.

exec
/bin/zsh -lc "rg -n \"rtl_check_uncited_findings|Unverified — no citation|Should — no falsifier|VERDICT\" relay-automation/relay-turn-lib.sh bin/validate-relay-block test/new-relay.sh test/relay-uncited-findings.sh 2>/dev/null
nl -ba relay-automation/relay-turn-lib.sh | sed -n '1210,1325p'
nl -ba test/new-relay.sh | sed -n '1,220p'
nl -ba test/relay-uncited-findings.sh | sed -n '1,260p'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-93733-mu26k550
 succeeded in 0ms:
test/new-relay.sh:55:VERDICT: PASS
test/new-relay.sh:66:VERDICT: PARKED
test/new-relay.sh:77:VERDICT: FAIL
test/relay-uncited-findings.sh:2:# test/relay-uncited-findings.sh — GH-173 B3: mechanically prove rtl_check_uncited_findings() catches
test/relay-uncited-findings.sh:24:rtl_check_uncited_findings "$F"
test/relay-uncited-findings.sh:25:grep -q '\[Unverified — no citation\] the retry logic looks correct' "$F" \
test/relay-uncited-findings.sh:26:  && pass "uncited [Pass] downgraded to [Unverified — no citation]" \
test/relay-uncited-findings.sh:29:# an [Unverified — no citation] suffix appended, which is exactly the regression a code-review
test/relay-uncited-findings.sh:43:rtl_check_uncited_findings "$F"
test/relay-uncited-findings.sh:54:rtl_check_uncited_findings "$F"
test/relay-uncited-findings.sh:64:rtl_check_uncited_findings "$F"
test/relay-uncited-findings.sh:65:grep -q 'I verified the change works as described.  \[Unverified — no citation\]' "$F" \
test/relay-uncited-findings.sh:71:rtl_check_uncited_findings "$F"
test/relay-uncited-findings.sh:96:rtl_check_uncited_findings "$F"
test/relay-uncited-findings.sh:97:grep -q 'Overall this looks good, no issues found, LGTM  \[Unverified — no citation\]' "$F" \
test/relay-uncited-findings.sh:109:rtl_check_uncited_findings "$F"
test/relay-uncited-findings.sh:161:rtl_check_uncited_findings "$F"
bin/validate-relay-block:75:# Extract the last VERDICT: line
bin/validate-relay-block:76:last_verdict="$(echo "$log_after" | grep -E -i '^[[:space:]]*[`*]*VERDICT[`*]*:' | tail -n 1 || true)"
bin/validate-relay-block:79:  echo "VERDICT: line is missing" >&2
bin/validate-relay-block:85:  echo "VERDICT: value must be exactly PASS, FAIL, or PARKED. Found: '$val'" >&2
bin/validate-relay-block:89:# Extract the final review block (the one containing the final VERDICT)
bin/validate-relay-block:98:toupper($0) ~ /^[[:space:]]*[*`]*VERDICT[*`]*:/ { has_verdict = 1 }
relay-automation/relay-turn-lib.sh:926:  rtl_trace "rtl_worktree_end: OFFLANE_VERDICT=$RTL_WT_OFFLANE"
relay-automation/relay-turn-lib.sh:1185:# are shared by both call sites below — rtl_check_uncited_findings's per-line downgrade, and
relay-automation/relay-turn-lib.sh:1217:rtl_check_uncited_findings() {  # <relay_file_path> — rewrites the file in place
relay-automation/relay-turn-lib.sh:1227:        if (line[i] ~ /\[Unverified — no citation\]/) { print line[i]; continue }
relay-automation/relay-turn-lib.sh:1236:        if (out ~ /\[Pass\]/) { gsub(/\[Pass\]/, "[Unverified — no citation]", out) }
relay-automation/relay-turn-lib.sh:1237:        else { out = out "  [Unverified — no citation]" }
relay-automation/relay-turn-lib.sh:1263:        if (line[i] ~ /\[Unverified — no citation\]/) continue
relay-automation/relay-turn-lib.sh:1299:        if (line[i] ~ /\[Unverified — no citation\]/) continue
relay-automation/relay-turn-lib.sh:1392:    rtl_check_uncited_findings "$RELAY_FILE"
relay-automation/relay-turn-lib.sh:1397:  # ## Log present, VERDICT, and Basis).
  1210	# TURN" block) now ASKS for a citation on any [Pass]/"verified" finding, but a prompt instruction is
  1211	# model compliance, not a guarantee — Jedi Wright's beta report hit exactly that gap (a "verified"
  1212	# claim with no quote). This does NOT verify a citation is ACCURATE (out of scope, no real
  1213	# citation-verification engine); it only catches the ABSENCE of one, mechanically, and downgrades the
  1214	# claim in place so the caveat is structural rather than trusting the model followed the instruction.
  1215	# A "citation" is a quoted span ("..."/`...`) or a file:line reference (name:NNN) within the next
  1216	# RTL_CITATION_WINDOW (default 3) lines, INCLUDING the claim's own line (inline citations count).
  1217	rtl_check_uncited_findings() {  # <relay_file_path> — rewrites the file in place
  1218	  local f="$1" win="${RTL_CITATION_WINDOW:-3}" tmp
  1219	  [[ -n "$f" && -f "$f" ]] || return 0
  1220	  tmp="${f}.rtlcite.$$"
  1221	  awk -v win="$win" -v word_re="$RTL_CLAIM_WORD_RE" -v cite_re="$RTL_CITATION_RE" '
  1222	    { line[NR] = $0 }
  1223	    END {
  1224	      for (i = 1; i <= NR; i++) {
  1225	        # already downgraded (prior pass) -> never re-flag. Required for idempotency: a prose "verified"
  1226	        # claim is appended-to, not replaced, so the trigger word "verified" is still on the line.
  1227	        if (line[i] ~ /\[Unverified — no citation\]/) { print line[i]; continue }
  1228	        claim = (line[i] ~ /\[Pass\]/) || (line[i] ~ word_re)
  1229	        if (!claim) { print line[i]; continue }
  1230	        cited = 0
  1231	        for (j = i; j <= NR && j <= i + win; j++) {
  1232	          if (line[j] ~ cite_re) { cited = 1; break }
  1233	        }
  1234	        if (cited) { print line[i]; continue }
  1235	        out = line[i]
  1236	        if (out ~ /\[Pass\]/) { gsub(/\[Pass\]/, "[Unverified — no citation]", out) }
  1237	        else { out = out "  [Unverified — no citation]" }
  1238	        print out
  1239	      }
  1240	    }
  1241	  ' "$f" > "$tmp" && mv "$tmp" "$f"
  1242	}
  1243	
  1244	# GH-178 A4 follow-up (code review on PR #184): read-only predicate reused by consult.sh's advisor
  1245	# citeless-stamp so B3 and A4 share one definition of "claim"/"citation" rather than two independent
  1246	# implementations drifting apart. Flags <file> as having an uncited claim if EITHER (a) the file has
  1247	# ZERO citations anywhere (the original A4 spec — "carries zero explicit citations anywhere"), OR
  1248	# (b) at least one claim-bearing line's own RTL_CITATION_WINDOW has no citation nearby, even though
  1249	# the file cites something elsewhere. (b) is the fix for the gap the code review flagged: the
  1250	# original consult.sh check only asked "is there a citation ANYWHERE in the whole transcript" — one
  1251	# incidental citation early in a long answer let several later uncited [Pass]/verified claims slip
  1252	# through unflagged. Mirrors grep -q's convention: exit 0 (true) = flag it, exit 1 = adequately cited.
  1253	# Missing/unreadable file fails safe (flagged), matching the old grep-based check's behavior on a
  1254	# missing $out.
  1255	rtl_has_uncited_claim() {  # <file>
  1256	  local f="$1" win="${RTL_CITATION_WINDOW:-3}"
  1257	  [[ -n "$f" && -f "$f" ]] || return 0
  1258	  awk -v win="$win" -v word_re="$RTL_CLAIM_WORD_RE" -v cite_re="$RTL_CITATION_RE" '
  1259	    { line[NR] = $0; if ($0 ~ cite_re) any_cite = 1 }
  1260	    END {
  1261	      flag = !any_cite
  1262	      for (i = 1; i <= NR && !flag; i++) {
  1263	        if (line[i] ~ /\[Unverified — no citation\]/) continue
  1264	        claim = (line[i] ~ /\[Pass\]/) || (line[i] ~ word_re)
  1265	        if (!claim) continue
  1266	        cited = 0
  1267	        for (j = i; j <= NR && j <= i + win; j++) {
  1268	          if (line[j] ~ cite_re) { cited = 1; break }
  1269	        }
  1270	        if (!cited) flag = 1
  1271	      }
  1272	      exit (flag ? 0 : 1)
  1273	    }
  1274	  ' "$f"
  1275	}
  1276	
  1277	# GH-235 A4 v0: prompt-trace classifier for ALREADY-CITED claims only. Shares the same claim/citation
  1278	# detector as rtl_has_uncited_claim() above; the only extra question is whether the nearby citation
  1279	# string was discovered firsthand in the transcript or merely echoed from the operator prompt text
  1280	# persisted by consult.sh. Known limitation: exact/whitespace-normalized substring matching can still
  1281	# false-FIRSTHAND when the advisor reformats a prompt citation (e.g. prompt says "consult.sh lines
  1282	# 117-126", answer cites consult.sh:117). v0 accepts that; do not fuzzy-match it here.
  1283	rtl_classify_cited_claims() {  # <transcript_file> <prompt_file>
  1284	  local transcript="$1" prompt="$2" win="${RTL_CITATION_WINDOW:-3}"
  1285	  [[ -n "$transcript" && -f "$transcript" && -n "$prompt" && -f "$prompt" ]] || return 0
  1286	  awk -v win="$win" -v word_re="$RTL_CLAIM_WORD_RE" -v cite_re="$RTL_CITATION_RE" '
  1287	    function norm(s,    t) {
  1288	      t = s
  1289	      gsub(/[[:space:]]+/, " ", t)
  1290	      sub(/^ /, "", t)
  1291	      sub(/ $/, "", t)
  1292	      return t
  1293	    }
  1294	    FNR == NR { prompt = prompt $0 "\n"; next }
  1295	    { line[NR] = $0 }
  1296	    END {
  1297	      prompt_norm = norm(prompt)
  1298	      for (i = 1; i <= NR; i++) {
  1299	        if (line[i] ~ /\[Unverified — no citation\]/) continue
  1300	        claim = (line[i] ~ /\[Pass\]/) || (line[i] ~ word_re)
  1301	        if (!claim) continue
  1302	        first_token = ""
  1303	        echoed_token = ""
  1304	        for (j = i; j <= NR && j <= i + win; j++) {
  1305	          rest = line[j]
  1306	          while (match(rest, cite_re)) {
  1307	            token = substr(rest, RSTART, RLENGTH)
  1308	            if (first_token == "") first_token = token
  1309	            if (index(prompt_norm, norm(token)) > 0) {
  1310	              echoed_token = token
  1311	              break
  1312	            }
  1313	            rest = substr(rest, RSTART + RLENGTH)
  1314	          }
  1315	          if (echoed_token != "") break
  1316	        }
  1317	        if (first_token == "") continue
  1318	        if (echoed_token != "") print "ECHOED " echoed_token
  1319	        else print "FIRSTHAND " first_token
  1320	      }
  1321	    }
  1322	  ' "$prompt" "$transcript"
  1323	}
  1324	
  1325	rtl_enforce() {  # <task> <agent> <log> <tool>
     1	#!/usr/bin/env bash
     2	# new-relay.sh — GH-31 Phase 4 (scaffolder) + Phase 3 (fence-safe embed). new-relay.sh emits a relay
     3	# thread the harness can drive (NEXT:/STATUS:/TAKE YOUR TURN/Setup/Log), in two artifact modes:
     4	#   - reference: Setup points at .relay-artifacts/<basename> (the read-only seed path, GH-31 Phase 2)
     5	#   - --embed:   inline the artifact in a fence LONGER than any backtick run inside it (no fence collision)
     6	source "$(dirname "$0")/_setup.sh" new-relay
     7	NR="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/new-relay.sh"
     8	
     9	# --- (1) reference mode: required fields present, artifact referenced at the seed path -------------
    10	out1="$(bash "$NR" --title "Review My PR" --reviewer codex --artifact-file /tmp/some-pr.diff --print)"
    11	grep -q '^NEXT: Reviewer$' <<<"$(printf '%s' "$out1")"      && pass "emits NEXT: Reviewer" || fail "missing NEXT (out: $out1)"
    12	grep -q '^STATUS: Open$' <<<"$(printf '%s' "$out1")"        && pass "emits STATUS: Open" || fail "missing STATUS"
    13	grep -q '▶ TAKE YOUR TURN' <<<"$(printf '%s' "$out1")"      && pass "emits the TAKE YOUR TURN block" || fail "missing turn block"
    14	grep -q '.relay-artifacts/some-pr.diff' <<<"$(printf '%s' "$out1")" && pass "references the read-only seed path" || fail "missing seed-path reference"
    15	grep -q 'Reviewer: codex' <<<"$(printf '%s' "$out1")"       && pass "names the reviewer" || fail "missing reviewer"
    16	grep -q '## Log' <<<"$(printf '%s' "$out1")"                && pass "emits a Log section" || fail "missing Log"
    17	
    18	# --- (2) slug derived from title; default out path under relay-system/<date>/ ----------------------
    19	out_path="$(cd "$A" && bash "$NR" --title "Review My PR" --reviewer agy 2>/dev/null)"
    20	case "$out_path" in
    21	  relay-system/*/review-my-pr.md) pass "derives slug + dated default path" ;;
    22	  *) fail "unexpected out path: $out_path" ;;
    23	esac
    24	[ -f "$A/$out_path" ] && pass "writes the thread file" || fail "thread file not written"
    25	
    26	# --- (3) FENCE-SAFE embed: artifact contains a 3-backtick fence → outer fence must be >=4 ----------
    27	ART="$WORK/nested.diff"
    28	printf 'diff --git a/x b/x\n+```\n+inner fenced block\n+```\n' >"$ART"   # inner run = 3 backticks
    29	out3="$(bash "$NR" --title "Nested" --reviewer codex --artifact-file "$ART" --embed --print)"
    30	# the opening fence the scaffolder chose: first line that is ONLY backticks
    31	fence_line="$(printf '%s\n' "$out3" | grep -E '^`+$' | head -1)"
    32	flen="${#fence_line}"
    33	[ "$flen" -ge 4 ] && pass "embed fence ($flen backticks) exceeds the inner 3-backtick run" || fail "fence too short ($flen) — collision risk"
    34	grep -q 'inner fenced block' <<<"$(printf '%s' "$out3")" && pass "artifact body is embedded" || fail "artifact not embedded"
    35	grep -q 'embedded below' <<<"$(printf '%s' "$out3")" && pass "Setup marks the artifact embedded" || fail "missing embedded marker"
    36	
    37	# --- (4) a 5-backtick run inside → fence must be >=6 (fence_for scales) ----------------------------
    38	ART2="$WORK/deep.txt"
    39	printf 'text\n`````\ncode\n`````\n' >"$ART2"   # inner run = 5 backticks
    40	out4="$(bash "$NR" --title "Deep" --reviewer agy --artifact-file "$ART2" --embed --print)"
    41	fence_line4="$(printf '%s\n' "$out4" | grep -E '^`+$' | head -1)"
    42	[ "${#fence_line4}" -ge 6 ] && pass "fence scales past a 5-backtick run (${#fence_line4} >= 6)" || fail "fence did not scale (${#fence_line4})"
    43	
    44	# --- (5) usage guards --------------------------------------------------------------------------------
    45	bash "$NR" --reviewer codex --print >/dev/null 2>&1 && fail "missing --title should error" || pass "errors without --title"
    46	bash "$NR" --title T --reviewer codex --embed --print >/dev/null 2>&1 && fail "--embed without artifact should error" || pass "errors on --embed without --artifact-file"
    47	
    48	# --- (6) integration: scaffolded thread passes structural validation after a valid reviewer turn -----
    49	VAL="$(cd "$(dirname "$0")/.." && pwd)/bin/validate-relay-block"
    50	out6="$(bash "$NR" --title "Integration Test" --reviewer agy --print)"
    51	TMP6="$WORK/integration.md"
    52	printf '%s\n' "$out6" > "$TMP6"
    53	cat >>"$TMP6" <<'EOF_TURN'
    54	### Reviewer · Round 1
    55	VERDICT: PASS
    56	Basis: simulated review turn on real scaffold
    57	EOF_TURN
    58	bash "$VAL" "$TMP6" >/dev/null 2>&1 && pass "scaffolded thread passes real validator" || fail "scaffolded thread failed validator"
    59	
    60	# --- (7) integration: scaffolded thread passes structural validation after a PARKED reviewer turn -----
    61	out7="$(bash "$NR" --title "Integration Test Parked" --reviewer agy --print)"
    62	TMP7="$WORK/integration-parked.md"
    63	printf '%s\n' "$out7" > "$TMP7"
    64	cat >>"$TMP7" <<'EOF_TURN'
    65	### Reviewer · Round 1
    66	VERDICT: PARKED
    67	Basis: simulated review turn on real scaffold, parked for now
    68	EOF_TURN
    69	bash "$VAL" "$TMP7" >/dev/null 2>&1 && pass "scaffolded thread passes real validator with PARKED verdict" || fail "scaffolded thread failed validator with PARKED verdict"
    70	
    71	# --- (8) integration: scaffolded thread passes structural validation after a FAIL reviewer turn -----
    72	out8="$(bash "$NR" --title "Integration Test Fail" --reviewer agy --print)"
    73	TMP8="$WORK/integration-fail.md"
    74	printf '%s\n' "$out8" > "$TMP8"
    75	cat >>"$TMP8" <<'EOF_TURN'
    76	### Reviewer · Round 1
    77	VERDICT: FAIL
    78	Basis: simulated review turn on real scaffold, failed
    79	EOF_TURN
    80	bash "$VAL" "$TMP8" >/dev/null 2>&1 && pass "scaffolded thread passes real validator with FAIL verdict" || fail "scaffolded thread failed validator with FAIL verdict"
    81	
    82	echo "  $TEST_NAME: $PASS pass, $FAIL fail"
    83	exit 0
     1	#!/usr/bin/env bash
     2	# test/relay-uncited-findings.sh — GH-173 B3: mechanically prove rtl_check_uncited_findings() catches
     3	# an uncited [Pass]/"verified" Reviewer claim and downgrades it in place, while leaving a genuinely
     4	# cited finding (quote or file:line, within the window) untouched — and that the downgrade itself is
     5	# NOT re-flagged on a later pass (the word "verified" is a substring of "Unverified"). Also covers the
     6	# code-review follow-up on PR #184: the widened RTL_CLAIM_WORD_RE trigger vocabulary (item 2), the
     7	# shared rtl_has_uncited_claim() read-only predicate consult.sh's A4 stamp now reuses (items 1 & 3),
     8	# and a regression guard (test 10) for the awk -v \[Pass\] corruption that follow-up briefly
     9	# introduced and a subsequent review pass caught.
    10	source "$(dirname "$0")/_setup.sh" relay-uncited-findings
    11	
    12	LIB="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-turn-lib.sh"
    13	# shellcheck source=relay-automation/relay-turn-lib.sh
    14	source "$LIB"
    15	
    16	F="$A/findings.md"
    17	
    18	# --- 1. uncited [Pass] -> downgraded ----------------------------------------------------------------
    19	cat >"$F" <<'EOF'
    20	## Log
    21	- [Pass] the retry logic looks correct
    22	- [Blocker] missing null check in handler
    23	EOF
    24	rtl_check_uncited_findings "$F"
    25	grep -q '\[Unverified — no citation\] the retry logic looks correct' "$F" \
    26	  && pass "uncited [Pass] downgraded to [Unverified — no citation]" \
    27	  || fail "uncited [Pass] NOT downgraded: $(cat "$F")"
    28	# Anchored at BOTH ends (not a prefix-only grep) — a prefix match would still "pass" if the line got
    29	# an [Unverified — no citation] suffix appended, which is exactly the regression a code-review
    30	# follow-up caught here: passing \[Pass\] through `awk -v` (rather than as an inline /regex/ literal)
    31	# silently corrupts it into a [Pass] BRACKET EXPRESSION under macOS's default awk, matching almost
    32	# any line containing a P/a/s character — including this one ("handler" has an 'a'). A prefix-only
    33	# check would not have caught that; see RTL_CLAIM_WORD_RE's warning comment in relay-turn-lib.sh.
    34	grep -qx '\- \[Blocker\] missing null check in handler' "$F" \
    35	  && pass "unrelated [Blocker] line left byte-for-byte untouched" \
    36	  || fail "[Blocker] line was mutated: $(cat "$F")"
    37	
    38	# --- 2. [Pass] with an inline quoted citation -> untouched ------------------------------------------
    39	cat >"$F" <<'EOF'
    40	## Log
    41	- [Pass] retry is bounded, see "for i in range(MAX_RETRIES)"
    42	EOF
    43	rtl_check_uncited_findings "$F"
    44	grep -q '^\- \[Pass\] retry is bounded' "$F" \
    45	  && pass "[Pass] with an inline quote left untouched" \
    46	  || fail "cited [Pass] was wrongly downgraded: $(cat "$F")"
    47	
    48	# --- 3. [Pass] with a file:line citation on the NEXT line (within window) -> untouched ---------------
    49	cat >"$F" <<'EOF'
    50	## Log
    51	- [Pass] input is validated before use
    52	  see relay-automation/consult.sh:266
    53	EOF
    54	rtl_check_uncited_findings "$F"
    55	grep -q '^\- \[Pass\] input is validated' "$F" \
    56	  && pass "[Pass] with a file:line citation on the next line left untouched" \
    57	  || fail "file:line-cited [Pass] was wrongly downgraded: $(cat "$F")"
    58	
    59	# --- 4. bare prose "verified" with no citation -> flagged --------------------------------------------
    60	cat >"$F" <<'EOF'
    61	## Log
    62	ANSWER: I verified the change works as described.
    63	EOF
    64	rtl_check_uncited_findings "$F"
    65	grep -q 'I verified the change works as described.  \[Unverified — no citation\]' "$F" \
    66	  && pass "uncited prose 'verified' claim flagged" \
    67	  || fail "uncited prose 'verified' claim NOT flagged: $(cat "$F")"
    68	
    69	# --- 5. idempotency: a downgraded line is not re-flagged on a second pass ----------------------------
    70	cp "$F" "$F.before"
    71	rtl_check_uncited_findings "$F"
    72	diff -q "$F.before" "$F" >/dev/null 2>&1 \
    73	  && pass "second pass over an already-downgraded line is a no-op (idempotent)" \
    74	  || fail "second pass mutated an already-downgraded line: $(cat "$F")"
    75	
    76	# --- 6. rtl_init captures RTL_WAS_REVIEWER_TURN before NEXT can flip ----------------------------------
    77	RELAY_R="$A/relay-reviewer.md"
    78	printf 'NEXT: Reviewer\nSTATUS: Open\n' >"$RELAY_R"
    79	rtl_init "$A" "$RELAY_R" ""
    80	[ "${RTL_WAS_REVIEWER_TURN:-0}" = "1" ] && pass "rtl_init sets RTL_WAS_REVIEWER_TURN=1 on a Reviewer turn" \
    81	  || fail "RTL_WAS_REVIEWER_TURN not set on a Reviewer turn"
    82	
    83	RELAY_P="$A/relay-producer.md"
    84	printf 'NEXT: Producer\nSTATUS: Open\n' >"$RELAY_P"
    85	rtl_init "$A" "$RELAY_P" ""
    86	[ "${RTL_WAS_REVIEWER_TURN:-0}" = "0" ] && pass "rtl_init sets RTL_WAS_REVIEWER_TURN=0 on a Producer turn" \
    87	  || fail "RTL_WAS_REVIEWER_TURN wrongly set on a Producer turn"
    88	
    89	# --- 7. code-review follow-up (item 2): widened trigger vocabulary catches an uncited claim that uses
    90	# none of the original 3 words ([Pass]/verified/confirmed) --------------------------------------------
    91	cat >"$F" <<'EOF'
    92	## Log
    93	- [Should] consider renaming this variable
    94	- Overall this looks good, no issues found, LGTM
    95	EOF
    96	rtl_check_uncited_findings "$F"
    97	grep -q 'Overall this looks good, no issues found, LGTM  \[Unverified — no citation\]' "$F" \
    98	  && pass "widened trigger vocabulary (looks good / no issues / LGTM) flags an uncited prose claim" \
    99	  || fail "widened trigger vocabulary NOT flagged: $(cat "$F")"
   100	grep -q '^\- \[Should\] consider renaming' "$F" \
   101	  && pass "unrelated [Should] line left untouched by the widened vocabulary" \
   102	  || fail "[Should] line was mutated: $(cat "$F")"
   103	
   104	# --- 8. same widened-vocabulary claim, but cited -> left untouched (non-regression) --------------------
   105	cat >"$F" <<'EOF'
   106	## Log
   107	- This checks out, see relay-automation/consult.sh:266
   108	EOF
   109	rtl_check_uncited_findings "$F"
   110	grep -q '^\- This checks out, see relay-automation/consult.sh:266$' "$F" \
   111	  && pass "widened-vocabulary claim with a file:line citation left untouched" \
   112	  || fail "cited widened-vocabulary claim was wrongly downgraded: $(cat "$F")"
   113	
   114	# --- 9. code-review follow-up (items 1 & 3): rtl_has_uncited_claim() — the read-only predicate
   115	# consult.sh's A4 stamp now shares with B3 — flags a transcript with an uncited claim even when SOME
   116	# unrelated citation exists elsewhere in the same file (the gap the review flagged: the old consult.sh
   117	# check only asked "any citation anywhere", so one incidental early citation excused later uncited
   118	# claims). It also still flags a transcript with zero citations anywhere (the original A4 spec), and
   119	# does NOT flag a transcript where every claim is cited near itself. ------------------------------------
   120	PARTIAL="$A/partial-cite.md"
   121	cat >"$PARTIAL" <<'EOF'
   122	ANSWER: confirmed by "return true always" at relay-automation/consult.sh:266.
   123	Later: [Pass] this other part also looks fine
   124	RECOMMENDATION: ship
   125	EOF
   126	rtl_has_uncited_claim "$PARTIAL" \
   127	  && pass "rtl_has_uncited_claim flags a later uncited claim despite an earlier unrelated citation" \
   128	  || fail "rtl_has_uncited_claim missed a later uncited claim: $(cat "$PARTIAL")"
   129	
   130	NOCITE="$A/no-cite.md"
   131	cat >"$NOCITE" <<'EOF'
   132	ANSWER: this looks correct.
   133	[Pass] no issues found
   134	RECOMMENDATION: ship
   135	EOF
   136	rtl_has_uncited_claim "$NOCITE" \
   137	  && pass "rtl_has_uncited_claim flags a transcript with zero citations anywhere" \
   138	  || fail "rtl_has_uncited_claim missed a fully-uncited transcript: $(cat "$NOCITE")"
   139	
   140	FULLYCITED="$A/fully-cited.md"
   141	cat >"$FULLYCITED" <<'EOF'
   142	ANSWER: confirmed by "return true always" at relay-automation/consult.sh:266.
   143	[Pass] verified — see relay-automation/consult.sh:266
   144	RECOMMENDATION: ship
   145	EOF
   146	rtl_has_uncited_claim "$FULLYCITED" \
   147	  && fail "rtl_has_uncited_claim wrongly flagged a transcript where every claim is cited near itself: $(cat "$FULLYCITED")" \
   148	  || pass "rtl_has_uncited_claim does not flag a transcript where every claim is cited near itself"
   149	
   150	# --- 10. regression guard: the [Pass] tag check must never be passed through `awk -v` -------------------
   151	# macOS's default /usr/bin/awk ("one true awk") string-unescapes a -v value before compiling it as a
   152	# dynamic regex, so a -v-passed \[Pass\] silently becomes the bracket EXPRESSION [Pass] — "any single
   153	# P, a, or s character" — instead of the literal tag, matching almost every line. A widened-vocabulary
   154	# follow-up on PR #184 introduced exactly this regression (caught in the SAME review pass, before it
   155	# reached main); this test pins the fix by feeding a line with plenty of P/a/s characters and NONE of
   156	# the real trigger words/tags, and asserting it is left completely untouched.
   157	cat >"$F" <<'EOF'
   158	## Log
   159	- A plain sentence with the letters P, a, and s scattered around it, and no real claim at all
   160	EOF
   161	rtl_check_uncited_findings "$F"
   162	grep -qx '\- A plain sentence with the letters P, a, and s scattered around it, and no real claim at all' "$F" \
   163	  && pass "a P/a/s-heavy non-claim line is left byte-for-byte untouched (no awk -v [Pass] corruption)" \
   164	  || fail "P/a/s-heavy line was wrongly flagged — the awk -v \\[Pass\\] corruption regressed: $(cat "$F")"
   165	
   166	# Same corruption class, exercised through rtl_has_uncited_claim(). A citation is included elsewhere
   167	# in the file (any_cite=1) specifically to rule OUT "zero citations anywhere" (the function's other,
   168	# intentional flag condition) as the reason it would flag this file — isolating the assertion to the
   169	# P/a/s corruption specifically.
   170	PASCORRUPT="$A/pas-corruption.md"
   171	cat >"$PASCORRUPT" <<'EOF'
   172	## Log
   173	- A plain sentence with the letters P, a, and s scattered around it, and no real claim at all
   174	- Actually cited elsewhere: see relay-automation/consult.sh:266
   175	EOF
   176	rtl_has_uncited_claim "$PASCORRUPT" \
   177	  && fail "rtl_has_uncited_claim wrongly flagged a P/a/s-heavy non-claim line — the awk -v corruption regressed: $(cat "$PASCORRUPT")" \
   178	  || pass "rtl_has_uncited_claim does not flag a P/a/s-heavy non-claim line (no awk -v [Pass] corruption)"
   179	
   180	echo "  $TEST_NAME: $PASS pass, $FAIL fail"
   181	exit 0

codex
The key seam is clearer: scratch containment already deliberately ignores `.relay-scratch/`, while ordinary ignored files are invisible to `git status`; I’m now checking whether the proposed Bash prompt is even the active Python-default path and whether “downgraded” in B has any actual validator behind it.
exec
/bin/zsh -lc "nl -ba relay-automation/codex-turn.sh | sed -n '1,220p'
nl -ba relay-automation/agy-turn.sh | sed -n '1,180p'
nl -ba relay-automation/claude-turn.sh | sed -n '1,180p'
rg -n \"role_note|REVIEWER this turn|relay-scratch|full project|programmatic|PYTHONDONTWRITEBYTECODE|read-only|sandbox|codex exec|def enforce|status --porcelain|git status\" utils/py/rtl.py utils/py/codex-turn.py utils/py/agy-turn.py utils/py/claude-turn.py utils/py/pi-turn.py relay-automation/*.sh
nl -ba utils/py/rtl.py | sed -n '180,285p;500,680p;760,900p'
nl -ba utils/py/codex-turn.py | sed -n '1,230p'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-93733-mu26k550
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# FROZEN (GH-308): Python is authoritative — do not make behavior changes here.
     3	# Historical Bash fallback only; update utils/py/codex-turn.py instead. See issue #308.
     4	set -euo pipefail
     5	
     6	# GH-112 opt-in Python mode: XYZ_PYTHON=1 reroutes this entry point to the Python port in
     7	# utils/py/ (same CLI contract + exit codes). Default (unset/0) runs the canonical Bash
     8	# implementation below — Bash stays the supported default until the port is promoted.
     9	if [[ "${XYZ_PYTHON-1}" == "1" ]]; then
    10	  # UPGRADE.md §4 Phase-2 hardening (GH-255): (2a) `-` not `:-` so an explicit empty XYZ_PYTHON reads
    11	  # as not-1 → Bash (load-bearing once the default flips to 1); (2b) require python3 >=3.8 and fall
    12	  # back to Bash with a warning if it's missing/too-old, so a bad interpreter degrades, not bricks.
    13	  if command -v python3 >/dev/null 2>&1 \
    14	     && python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
    15	    _xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    16	    export XYZ_ROOT="$_xyz_root"
    17	    export PYTHONPATH="$_xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
    18	    exec python3 "$_xyz_root/utils/py/codex-turn.py" "$@"
    19	  else
    20	    echo "xyz: XYZ_PYTHON=1 but python3 missing or < 3.8 — falling back to Bash" >&2
    21	  fi
    22	fi
    23	#
    24	# codex-turn.sh — headless turn-taker for the CODEX agent. Thin dispatch wrapper over the
    25	# shared safety core (relay-turn-lib.sh); the containment contract lives there.
    26	#
    27	# Invoked by relay-drive.sh as --agent-cmd, with env:
    28	#   RELAY_FILE  — relay thread file (always allowlisted)
    29	#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
    30	#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
    31	# Shim config:
    32	#   CODEX_AGENT     — the agent id this shim drives; NO-OPS unless RELAY_AGENT==CODEX_AGENT
    33	#   ALLOW_PATHS     — comma-separated extra git paths the turn may change (e.g. the artifact)
    34	#   RELAY_PEER      — optional: the other agent's id, so the turn hands off "--to <peer>" (else the
    35	#                     prompt says "the other agent", which a live model may resolve to a role name)
    36	#   CODEX_BIN       — codex binary (default: codex); tests inject a stub
    37	#   CODEX_FLAGS     — autonomy flags for `codex exec` (default: -s workspace-write -c
    38	#                     approval_policy=never — GH-106: the old bare `-s workspace-write` default still
    39	#                     gated some actions behind an interactive approval prompt, which hangs forever in
    40	#                     a headless run until RELAY_TURN_TIMEOUT_S kills it (exit 7), burning a lane
    41	#                     attempt). If codex still blocks on some other prompt type, escalate with e.g.
    42	#                     CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox' (removes codex's own
    43	#                     sandbox entirely; this repo's containment then relies solely on
    44	#                     relay-turn-lib.sh's worktree isolation, same as every other headless worker).
    45	#   CODEX_TURN_ROOT — git root to guard (default: this repo); tests point at a fixture
    46	#   CODEX_LOG       — where to write the codex transcript (default: GH-161 persistent path under
    47	#                     rtl_transcript_root(ROOT)/logs/, gitignored; falls back to a $TMPDIR file on any
    48	#                     resolver failure). Also exported as RTL_LOG so relay-turn-lib.sh's rtl_trace/
    49	#                     rtl_log_always decision-point instrumentation lands in this same transcript.
    50	#   RTL_TRACE       — 1 = also emit fine-grained decision-point trace lines (root resolution,
    51	#                     allowlist match, worktree seed/copy-back, containment verdict) into CODEX_LOG.
    52	#                     Default off — the routine successful path stays quiet unless requested.
    53	#   RELAY_WORKTREE_ISOLATION — 1 = run the turn in a THROWAWAY git worktree of ROOT@HEAD (airtight
    54	#                     async/side-effect containment; off-lane in the worktree → exit 6). Default OFF.
    55	#
    56	#   RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds (default: 900). A hung or
    57	#                          runaway codex CLI is killed after this many seconds; the turn exits 7.
    58	#
    59	# Exit: 0 acted/deferred · 5 codex failed / token ownership missing · 6 off-allowlist edit
    60	#       (reverted) · 7 timeout-killed · 2 usage.
    61	
    62	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    63	# shellcheck source=relay-turn-lib.sh
    64	source "$HERE/relay-turn-lib.sh"
    65	
    66	# Default ROOT to the CWD's git toplevel (the repo the operator is actually driving) so a
    67	# NON-VENDORED run — this shim invoked from outside the target repo, e.g. straight from the swarm
    68	# checkout — roots worktree isolation + artifact copyback at the TARGET, not this shim's own repo
    69	# ($HERE/..). Explicit CODEX_TURN_ROOT still wins (fixtures); fall back to $HERE/.. off a git repo.
    70	ROOT="${CODEX_TURN_ROOT:-"$(git rev-parse --show-toplevel 2>/dev/null || (cd "$HERE/.." && pwd))"}"
    71	CODEX_BIN="${CODEX_BIN:-codex}"
    72	die() { printf 'codex-turn: %s\n' "$*" >&2; exit 2; }
    73	
    74	me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
    75	codex_agent="${CODEX_AGENT:-}"
    76	[[ -n "$me" ]] || die "RELAY_AGENT required"
    77	[[ -n "$f" ]] || die "RELAY_FILE required"
    78	[[ -n "$codex_agent" ]] || die "CODEX_AGENT required"
    79	
    80	# Dispatch only for the Codex agent; defer otherwise (that window drives its own turn).
    81	if [[ "$me" != "$codex_agent" ]]; then
    82	  printf 'codex-turn: actor %s is not the Codex agent (%s) — deferring (window-driven)\n' "$me" "$codex_agent" >&2
    83	  exit 0
    84	fi
    85	
    86	# Anchor tick coordination to the harness root (not just under worktree isolation): the turn-prompt
    87	# and every token op must resolve .tick + bin/tick there regardless of the turn's CWD. Preserve an
    88	# inherited TICK_REPO_ROOT from marathon-drive/relay-drive (notably a vendored .xyz run whose real
    89	# harness root is the CONSUMER repo, not .xyz itself); default to ROOT only when the caller did not
    90	# already pin it. (GH-171)
    91	: "${TICK_REPO_ROOT:=$ROOT}"
    92	export TICK_REPO_ROOT
    93	# GH-161: resolve the transcript path and export RTL_LOG BEFORE rtl_init, so its own decision-trace
    94	# line (and every later rtl_trace/rtl_log_always call) lands in this turn's transcript. Persistent by
    95	# default (rtl_transcript_root-anchored, gitignored — see .gitignore); falls back to the historical
    96	# PID-keyed tmp path on any resolver failure. CODEX_LOG stays fully operator-overridable.
    97	CODEX_LOG="${CODEX_LOG:-$(rtl_default_log "$ROOT" codex-turn "$t")}"
    98	export RTL_LOG="$CODEX_LOG"
    99	rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"
   100	prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
   101	# GH-68 warn-only: prepend any UNREAD cross-agent dependency-drift heads-up to the turn brief, so a
   102	# builder learns a peer changed a shared surface (kernel/projection/schema) since its last turn. No
   103	# unread drift → empty → prompt unchanged. Never blocks. (decisions/2026-07-01-cross-agent-dep-conflict.md)
   104	drift_brief="$(rtl_drift_brief "$me" "${TICK_REPO_ROOT:-$ROOT}")"
   105	[[ -n "$drift_brief" ]] && prompt="${drift_brief}"$'\n'"${prompt}"
   106	
   107	# GH-165: claim the specific handed-off task in the shim and prove ownership BEFORE launching Codex.
   108	# GH-67 already backstops release/done after the commit, but that path is ownership-guarded by tick:
   109	# if Codex edits the relay/artifacts without first becoming the claimer, rtl_enforce can only WARN
   110	# and the lane deadlocks as apparent "no-progress". Claiming here is safe because `tick claim` is
   111	# idempotent when this agent already holds the token.
   112	claim_paths="${f#"$ROOT"/}"
   113	if [[ -n "${ALLOW_PATHS:-}" ]]; then
   114	  IFS=',' read -ra _claim_allow <<<"${ALLOW_PATHS}"
   115	  for _ap in "${_claim_allow[@]}"; do
   116	    _ap="${_ap#"${_ap%%[![:space:]]*}"}"
   117	    _ap="${_ap%"${_ap##*[![:space:]]}"}"
   118	    [[ -n "$_ap" ]] && claim_paths="$claim_paths,$_ap"
   119	  done
   120	fi
   121	_tickroot="${TICK_REPO_ROOT:-$ROOT}"; _tickbin="$(rtl_tick_bin "$_tickroot")"
   122	if [[ -x "$_tickbin" ]]; then
   123	  TICK_REPO_ROOT="$_tickroot" "$_tickbin" claim "$t" --agent "$me" --paths "$claim_paths" >/dev/null 2>&1 || true
   124	  _claimer="$(TICK_REPO_ROOT="$_tickroot" "$_tickbin" info "$t" 2>/dev/null | sed -n 's/^claimer:[[:space:]]*//p' | head -n1)"
   125	  if [[ "$_claimer" != "$me" ]]; then
   126	    printf 'codex-turn: could not establish token ownership of %s (claimer=%s, expected %s) — refusing to run so the turn cannot commit with the token open under the old owner; inspect `tick info %s`\n' "$t" "${_claimer:-none}" "$me" "$t" >&2
   127	    exit 5
   128	  fi
   129	  TICK_REPO_ROOT="$_tickroot" "$_tickbin" ping "$t" --agent "$me" >/dev/null 2>&1 || true
   130	fi
   131	
   132	# Run the Codex turn headless (token ops + edit the relay file; NO git), then enforce the boundary.
   133	# CODEX_FLAGS gives the turn enough autonomy to actually write on a fresh device (default sandbox is
   134	# read-only); operator-overridable for tighter/looser policies.
   135	# GH-106: default adds `-c approval_policy=never` to the sandbox flag so a headless run no longer
   136	# hangs on an interactive approval prompt until RELAY_TURN_TIMEOUT_S kills it (exit 7). Keeps the
   137	# workspace-write sandbox restriction (still can't touch outside the workspace) — fully overridable.
   138	read -ra _cflags <<<"${CODEX_FLAGS:--s workspace-write -c approval_policy=never}"
   139	codex_extra_flags=()
   140	# Transcript: CODEX_LOG is already resolved above (persistent-by-default via rtl_default_log, or a
   141	# tmp fallback — see the comment at the RTL_LOG export). Persists the transcript so the headless run
   142	# is auditable. (Codex token-stats parsing is a follow-up — its usage format isn't probed yet, so
   143	# cost.tokens for Codex turns stays a Phase-1 partial.)
   144	rtl_before
   145	turn_timeout="${RELAY_TURN_TIMEOUT_S:-900}"
   146	bounded_rc=0
   147	
   148	# Worktree isolation (opt-in; ROADMAP Part A Phase 3.6 — same wiring as claude-turn.sh / agy-turn.sh).
   149	# When RELAY_WORKTREE_ISOLATION=1, run codex with CWD = a THROWAWAY git worktree of ROOT@HEAD, so any
   150	# async/background write lands in a tree we delete, never ROOT. .tick stays SHARED via TICK_REPO_ROOT.
   151	# Default OFF → the in-ROOT run below is byte-for-byte the prior behaviour.
   152	wt=""; cwd_wrap=()
   153	if [[ "${RELAY_WORKTREE_ISOLATION:-0}" == "1" ]]; then
   154	  if wt="$(rtl_worktree_begin)"; then
   155	    # TICK_REPO_ROOT already exported above (unconditional) — .tick stays SHARED with ROOT here.
   156	    cwd_wrap=(bash -c 'cd "$1" || exit 127; shift; exec "$@"' bash "$wt")
   157	    # GH-36: the isolated worktree is the primary workspace, so the shared token lock under
   158	    # $TICK_REPO_ROOT/.tick is outside Codex's default workspace-write sandbox unless we add it.
   159	    codex_extra_flags=(--add-dir "$TICK_REPO_ROOT/.tick")
   160	    printf 'codex-turn: worktree isolation ON (%s)\n' "$wt" >&2
   161	  else
   162	    printf 'codex-turn: worktree isolation requested but `git worktree add` failed — failing turn\n' >&2
   163	    exit 5
   164	  fi
   165	else
   166	  # GH-263: the isolation=0 (default/opt-out) path used to add nothing here, on the assumption
   167	  # that Codex's CWD already equals ROOT so $TICK_REPO_ROOT/.tick sits inside its workspace-write
   168	  # sandbox for free. That assumption breaks in a vendored `.xyz/` install driven from `cd
   169	  # $HARNESS` (relay-xyz's documented CWD): Codex's CWD is `.xyz`, so the parent-root .tick is
   170	  # OUTSIDE its sandbox and the `tick claim` lock write EPERMs before the turn even starts. Reuse
   171	  # the same GH-36 flag here so Codex's sandbox can always reach the shared token lock, whether or
   172	  # not its CWD happens to already contain it (harmless no-op when CWD already covers .tick).
   173	  codex_extra_flags=(--add-dir "$TICK_REPO_ROOT/.tick")
   174	fi
   175	
   176	# Billing guard: strip OPENAI_API_KEY from the codex subprocess env so a Codex turn ALWAYS bills
   177	# against the ChatGPT-subscription login (`~/.codex/auth.json` auth_mode=chatgpt), never per-token API
   178	# credits — even if some ambient session exported a key. Set CODEX_ALLOW_API_KEY=1 to opt back in.
   179	codex_env=(env)
   180	[[ "${CODEX_ALLOW_API_KEY:-0}" == "1" ]] || codex_env+=(-u OPENAI_API_KEY)
   181	# GH-161: >> (append), not > (truncate) — rtl_init already wrote its trace line into CODEX_LOG above
   182	# (RTL_LOG was exported before rtl_init ran); a truncating redirect here would silently wipe it. Still
   183	# effectively a fresh file per turn under the persistent default (each run's filename embeds $$).
   184	rtl_run_bounded "$turn_timeout" ${cwd_wrap[@]+"${cwd_wrap[@]}"} "${codex_env[@]}" "$CODEX_BIN" exec "${_cflags[@]}" ${codex_extra_flags[@]+"${codex_extra_flags[@]}"} "$prompt" < /dev/null >> "$CODEX_LOG" 2>&1 \
   185	  || bounded_rc=$?
   186	
   187	# Worktree teardown FIRST (regardless of rc). Copies the allowlist back to ROOT unless an off-lane
   188	# change was detected → exit 6 (containment takes precedence over timeout 7 / failure 5).
   189	if [[ -n "$wt" ]]; then
   190	  rtl_worktree_end "$wt"
   191	  if [[ "${RTL_WT_OFFLANE:-0}" == "1" ]]; then
   192	    printf 'codex-turn: codex made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)\n' >&2
   193	    exit 6
   194	  fi
   195	fi
   196	
   197	if [[ "$bounded_rc" -eq 7 ]]; then
   198	  printf 'codex-turn: codex exec exceeded %ss wall-clock cap — killed\n' "$turn_timeout" >&2
   199	elif [[ "$bounded_rc" -ne 0 ]]; then
   200	  printf 'codex-turn: codex exec failed (exit %s)\n' "$bounded_rc" >&2; exit 5
   201	fi
   202	# Always enforce containment even after a timeout-kill: a killed-mid-edit agent may have left
   203	# off-lane changes. rtl_enforce may exit 6 (containment violation takes precedence over timeout 7).
   204	rtl_enforce "$t" "$me" "$CODEX_LOG" "codex"
   205	if [[ "$bounded_rc" -eq 7 ]]; then exit 7; fi
     1	#!/usr/bin/env bash
     2	# FROZEN (GH-308): Python is authoritative — do not make behavior changes here.
     3	# Historical Bash fallback only; update utils/py/agy-turn.py instead. See issue #308.
     4	set -euo pipefail
     5	
     6	# GH-112 opt-in Python mode: XYZ_PYTHON=1 reroutes this entry point to the Python port in
     7	# utils/py/ (same CLI contract + exit codes). Default (unset/0) runs the canonical Bash
     8	# implementation below — Bash stays the supported default until the port is promoted.
     9	if [[ "${XYZ_PYTHON-1}" == "1" ]]; then
    10	  # UPGRADE.md §4 Phase-2 hardening (GH-255): (2a) `-` not `:-` so an explicit empty XYZ_PYTHON reads
    11	  # as not-1 → Bash (load-bearing once the default flips to 1); (2b) require python3 >=3.8 and fall
    12	  # back to Bash with a warning if it's missing/too-old, so a bad interpreter degrades, not bricks.
    13	  if command -v python3 >/dev/null 2>&1 \
    14	     && python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
    15	    _xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    16	    export XYZ_ROOT="$_xyz_root"
    17	    export PYTHONPATH="$_xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
    18	    exec python3 "$_xyz_root/utils/py/agy-turn.py" "$@"
    19	  else
    20	    echo "xyz: XYZ_PYTHON=1 but python3 missing or < 3.8 — falling back to Bash" >&2
    21	  fi
    22	fi
    23	#
    24	# agy-turn.sh — headless turn-taker for the ANTIGRAVITY CLI (`agy`). Thin dispatch wrapper over the
    25	# shared safety core (relay-turn-lib.sh) — the SAME containment contract as codex-turn.sh /
    26	# gemini-turn.sh, proving the boundary is model-agnostic
    27	# (decisions/2026-06-15-unattended-agent-containment.md).
    28	#
    29	# WHY THIS EXISTS: permanent cross-model lane, replacing gemini-turn.sh. Gemini CLI was retired
    30	# 2026-06-19. `agy` (Antigravity CLI) is authed off the signed-in Antigravity desktop app and is
    31	# itself a multi-model gateway (Gemini / Claude / GPT-OSS via --model).
    32	#
    33	# Invoked by relay-drive.sh / marathon-agent.sh as --agent-cmd, with env:
    34	#   RELAY_FILE  — relay thread file (always allowlisted)
    35	#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
    36	#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
    37	# Shim config:
    38	#   AGY_AGENT      — the agent id this shim drives; NO-OPS unless RELAY_AGENT==AGY_AGENT
    39	#   ALLOW_PATHS    — comma-separated extra git paths the turn may change (e.g. the artifact)
    40	#   RELAY_PEER     — optional: the other agent's id, so the turn hands off "--to <peer>" (else the
    41	#                    prompt says "the other agent", which a live model may resolve to a role name)
    42	#   AGY_BIN        — agy binary (default: agy); tests inject a stub
    43	#   AGY_MODEL      — optional model for the turn (e.g. "Gemini 3.1 Pro (High)"); unset ⇒ agy default
    44	#   AGY_FLAGS      — optional extra flags appended to the agy invocation (advanced/override)
    45	#   AGY_TURN_ROOT  — git root to guard (default: this repo); tests point at a fixture
    46	#   AGY_LOG        — where to write the agy transcript (default: GH-161 persistent path under
    47	#                    rtl_transcript_root(ROOT)/logs/, gitignored; falls back to a $TMPDIR file on any
    48	#                    resolver failure). Also exported as RTL_LOG so relay-turn-lib.sh's rtl_trace/
    49	#                    rtl_log_always decision-point instrumentation lands in this same transcript.
    50	#   RTL_TRACE      — 1 = also emit fine-grained decision-point trace lines (root resolution, allowlist
    51	#                    match, worktree seed/copy-back, containment verdict) into AGY_LOG. Default off.
    52	#   AGY_AUTH_TIMEOUT_S — short wall-clock cap for the auth pre-flight probe (`agy whoami`);
    53	#                        default 5. On failure/time-out the shim exits 5 with an `agy login` remedy.
    54	#   RELAY_WORKTREE_ISOLATION — 1 = run the turn in a THROWAWAY git worktree of ROOT@HEAD (airtight
    55	#                     async/side-effect containment; off-lane in the worktree → exit 6). Default OFF.
    56	#
    57	# Auth/headless contract (validated 2026-06-18, agy from Antigravity.app):
    58	#   -p "<prompt>"                  — non-interactive (headless) print mode
    59	#   --dangerously-skip-permissions — auto-approve tool calls (shell for tick, edit for the relay file)
    60	#   --print-timeout <dur>          — agy's own print-mode wait; pinned to the wall-clock cap so agy
    61	#                                    returns on its own before the rtl watchdog has to kill it
    62	#   `agy whoami`                   — cheap pre-flight auth probe; if it fails or hangs, the shim skips
    63	#                                    the lane fast with "run `agy login`" instead of letting `agy -p`
    64	#                                    open an interactive auth prompt that deadlocks the headless turn
    65	#
    66	#   RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds (default: 900). A hung or
    67	#                          runaway agy CLI is killed after this many seconds; the turn exits 7.
    68	#
    69	# TWO agy-specific gotchas this shim guards (memory: agy-antigravity-cli):
    70	#   (a) SILENT FAILURE UNDER A SANDBOX — when agy's backend network is blocked (e.g. Claude Code's
    71	#       Bash sandbox) `agy -p` exits 0 with EMPTY output. An empty "successful" turn is a FALSE
    72	#       success for an automated relay, so we treat empty-output-on-exit-0 as a hard failure (exit 5).
    73	#       Run this shim with the sandbox OFF (like codex; memory: codex-cli-needs-sandbox-disabled).
    74	#   (b) NO JSON / TOKEN OUTPUT — agy print mode has no `-o json` and no usage block, so there is NO
    75	#       cost.tokens capture here (an agy lane is cost-blind — a floor, same Phase-1 partial as Codex).
    76	#
    77	# Exit: 0 acted/deferred · 5 agy failed or produced empty output · 6 off-allowlist edit (reverted) ·
    78	#       7 timeout-killed · 2 usage.
    79	
    80	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    81	# shellcheck source=relay-turn-lib.sh
    82	source "$HERE/relay-turn-lib.sh"
    83	
    84	# Default ROOT to the CWD's git toplevel (the repo the operator is actually driving) so a
    85	# NON-VENDORED run — this shim invoked from outside the target repo, e.g. straight from the swarm
    86	# checkout — roots worktree isolation + artifact copyback at the TARGET, not this shim's own repo
    87	# ($HERE/..). Explicit AGY_TURN_ROOT still wins (fixtures); fall back to $HERE/.. off a git repo.
    88	ROOT="${AGY_TURN_ROOT:-"$(git rev-parse --show-toplevel 2>/dev/null || (cd "$HERE/.." && pwd))"}"
    89	AGY_BIN="${AGY_BIN:-agy}"
    90	die() { printf 'agy-turn: %s\n' "$*" >&2; exit 2; }
    91	agy_auth_preflight() {
    92	  local secs="${AGY_AUTH_TIMEOUT_S:-5}" out rc=0 line
    93	  out="${TMPDIR:-/tmp}/agy-auth-$$.log"
    94	  rtl_run_bounded "$secs" "$AGY_BIN" whoami < /dev/null > "$out" 2>&1 || rc=$?
    95	  [[ "$rc" -eq 0 ]] && { rm -f "$out"; return 0; }
    96	  if [[ "$rc" -eq 7 ]]; then
    97	    printf 'agy-turn: agy auth pre-flight timed out after %ss; likely expired auth opening an interactive login. Run `agy login` in a normal terminal, then retry.\n' "$secs" >&2
    98	  else
    99	    printf 'agy-turn: agy auth pre-flight failed (exit %s). Run `agy login` in a normal terminal, then retry.\n' "$rc" >&2
   100	  fi
   101	  while IFS= read -r line; do
   102	    [[ -n "$line" ]] || continue
   103	    printf 'agy-turn: auth pre-flight: %s\n' "$line" >&2
   104	  done < <(sed -n '1,3p' "$out")
   105	  rm -f "$out"
   106	  return 1
   107	}
   108	agy_validate_model() {
   109	  local model="${AGY_MODEL:-}" secs="${AGY_AUTH_TIMEOUT_S:-5}" out rc=0 line
   110	  [[ -n "$model" ]] || return 0
   111	  out="${TMPDIR:-/tmp}/agy-models-$$.log"
   112	  rtl_run_bounded "$secs" "$AGY_BIN" models < /dev/null > "$out" 2>&1 || rc=$?
   113	  if [[ "$rc" -ne 0 ]]; then
   114	    if [[ "$rc" -eq 7 ]]; then
   115	      printf 'agy-turn: agy models probe timed out after %ss while validating AGY_MODEL=%q. Refusing to fall back silently.\n' "$secs" "$model" >&2
   116	    else
   117	      printf 'agy-turn: agy models probe failed (exit %s) while validating AGY_MODEL=%q. Refusing to fall back silently.\n' "$rc" "$model" >&2
   118	    fi
   119	    while IFS= read -r line; do
   120	      [[ -n "$line" ]] || continue
   121	      printf 'agy-turn: models probe: %s\n' "$line" >&2
   122	    done < <(sed -n '1,3p' "$out")
   123	    rm -f "$out"
   124	    return 1
   125	  fi
   126	  while IFS= read -r line; do
   127	    line="${line%$'\r'}"
   128	    [[ "$line" == "$model" ]] && { rm -f "$out"; return 0; }
   129	  done < "$out"
   130	  printf 'agy-turn: requested AGY_MODEL=%q is unavailable on this agy account. Run `agy models` to choose a listed model; refusing to fall back silently.\n' "$model" >&2
   131	  rm -f "$out"
   132	  return 1
   133	}
   134	
   135	me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
   136	agy_agent="${AGY_AGENT:-}"
   137	[[ -n "$me" ]] || die "RELAY_AGENT required"
   138	[[ -n "$f" ]] || die "RELAY_FILE required"
   139	[[ -n "$agy_agent" ]] || die "AGY_AGENT required"
   140	
   141	# Dispatch only for the agy agent; defer otherwise (that window drives its own turn).
   142	if [[ "$me" != "$agy_agent" ]]; then
   143	  printf 'agy-turn: actor %s is not the agy agent (%s) — deferring (window-driven)\n' "$me" "$agy_agent" >&2
   144	  exit 0
   145	fi
   146	
   147	agy_auth_preflight || exit 5
   148	agy_validate_model || exit 5
   149	# Preserve an inherited harness tick root from the orchestrator (e.g. vendored .xyz marathon runs);
   150	# default to this shim's ROOT only when the caller did not already pin TICK_REPO_ROOT. (GH-171)
   151	: "${TICK_REPO_ROOT:=$ROOT}"
   152	export TICK_REPO_ROOT
   153	# GH-161: resolve the transcript path and export RTL_LOG BEFORE rtl_init (same reasoning as
   154	# codex-turn.sh) so its decision-trace line, and every later rtl_trace/rtl_log_always call, lands in
   155	# this turn's transcript. Persistent by default; falls back to the historical PID-keyed tmp path on
   156	# any resolver failure. AGY_LOG stays fully operator-overridable.
   157	AGY_LOG="${AGY_LOG:-$(rtl_default_log "$ROOT" agy-turn "$t")}"
   158	export RTL_LOG="$AGY_LOG"
   159	rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"
   160	
   161	# Cross-repo footgun guard (consumer feedback KWFS-02 B2): agy reads file paths relative to its
   162	# PROCESS CWD (the tooling repo), NOT AGY_TURN_ROOT. So in cross-repo mode — guarding a different
   163	# repo than CWD — any RELATIVE TARGET path in the relay file resolves against the wrong tree and agy
   164	# silently "finds nothing." Warn loudly (non-fatal); the fix is absolute TARGET paths. See CONSUMING.md.
   165	_cwd_git_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
   166	if [[ -n "$_cwd_git_root" && "$(cd "$ROOT" 2>/dev/null && pwd)" != "$_cwd_git_root" ]]; then
   167	  printf 'agy-turn: CROSS-REPO mode (AGY_TURN_ROOT=%s != CWD git root=%s) — agy resolves relative paths against CWD, not the target repo. List TARGET files by ABSOLUTE path in %s or agy will silently find nothing. (CONSUMING.md)\n' "$ROOT" "$_cwd_git_root" "$f" >&2
   168	fi
   169	
   170	prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
   171	# GH-68 warn-only: prepend any UNREAD cross-agent dependency-drift heads-up to the turn brief, so a
   172	# builder learns a peer changed a shared surface (kernel/projection/schema) since its last turn. No
   173	# unread drift → empty → prompt unchanged. Never blocks. (decisions/2026-07-01-cross-agent-dep-conflict.md)
   174	drift_brief="$(rtl_drift_brief "$me" "${TICK_REPO_ROOT:-$ROOT}")"
   175	[[ -n "$drift_brief" ]] && prompt="${drift_brief}"$'\n'"${prompt}"
   176	
   177	# GH-171 follow-up: mirror the Codex/Aider claim-before-launch guard. A driven agy turn that edits the
   178	# relay/artifact but never claims the specific handed-off token leaves GH-67's post-commit handoff with
   179	# no authority, so the lane deadlocks as apparent "no-progress". Claiming here is idempotent when agy
   180	# already holds the token.
     1	#!/usr/bin/env bash
     2	# FROZEN (GH-308): Python is authoritative — do not make behavior changes here.
     3	# Historical Bash fallback only; update utils/py/claude-turn.py instead. See issue #308.
     4	set -euo pipefail
     5	
     6	# GH-112 opt-in Python mode: XYZ_PYTHON=1 reroutes this entry point to the Python port in
     7	# utils/py/ (same CLI contract + exit codes). Default (unset/0) runs the canonical Bash
     8	# implementation below — Bash stays the supported default until the port is promoted.
     9	if [[ "${XYZ_PYTHON-1}" == "1" ]]; then
    10	  # UPGRADE.md §4 Phase-2 hardening (GH-255): (2a) `-` not `:-` so an explicit empty XYZ_PYTHON reads
    11	  # as not-1 → Bash (load-bearing once the default flips to 1); (2b) require python3 >=3.8 and fall
    12	  # back to Bash with a warning if it's missing/too-old, so a bad interpreter degrades, not bricks.
    13	  if command -v python3 >/dev/null 2>&1 \
    14	     && python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
    15	    _xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    16	    export XYZ_ROOT="$_xyz_root"
    17	    export PYTHONPATH="$_xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
    18	    exec python3 "$_xyz_root/utils/py/claude-turn.py" "$@"
    19	  else
    20	    echo "xyz: XYZ_PYTHON=1 but python3 missing or < 3.8 — falling back to Bash" >&2
    21	  fi
    22	fi
    23	# GH-613: subscription opt-in must not enter an unsupported legacy path.
    24	if [[ "${CLAUDE_AUTH_MODE:-inherit}" == subscription ]]; then
    25	  echo "xyz: subscription requires the Python runtime (XYZ_PYTHON=1 and python3 >= 3.8)" >&2
    26	  exit 5
    27	fi
    28	#
    29	# claude-turn.sh — headless turn-taker for the CLAUDE builder agent. Thin dispatch wrapper over the
    30	# shared safety core (relay-turn-lib.sh) — the SAME containment contract as codex-turn.sh and
    31	# gemini-turn.sh (decisions/2026-06-15-unattended-agent-containment.md).
    32	#
    33	# Builder role: Claude is the PRODUCER (write/revise the artifact). Reviewers (Codex, Gemini) use
    34	# the tighter "Bash,Read" allowlist — no Write surface; rtl_enforce is the real guard regardless.
    35	#
    36	# Invoked by relay-drive.sh as --agent-cmd (typically via marathon-agent.sh), with env:
    37	#   RELAY_FILE  — relay thread file (always allowlisted)
    38	#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
    39	#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
    40	# Shim config:
    41	#   CLAUDE_AGENT      — the agent id this shim drives; NO-OPS unless RELAY_AGENT==CLAUDE_AGENT
    42	#   ALLOW_PATHS       — comma-separated extra git paths the turn may change (the artifact being built)
    43	#   RELAY_PEER        — optional: the other agent's id, for explicit --to <peer> handoff
    44	#   CLAUDE_BIN        — claude CLI binary or wrapper (default: claude); tests inject a stub.
    45	#   CLAUDE_MODEL      — model to PIN via --model (default: claude-sonnet-4-6). Without this the
    46	#                       headless turn inherits the operator's ambient model — an Opus session blew
    47	#                       the budget cap mid-build on 2026-06-18. Pin it so cost is deterministic.
    48	#   CLAUDE_TURN_ROOT  — git root to guard (default: this repo); tests point at a fixture
    49	#   CLAUDE_LOG        — where to write the claude transcript JSON (default: $TMPDIR/claude-turn-$$.json)
    50	#   CLAUDE_MAX_TURNS  — max turns passed to --max-turns (default: 12)
    51	#   CLAUDE_MAX_BUDGET — max cost passed to --max-budget-usd (default: 0.50)
    52	#   CLAUDE_BLOCK_CMDS — space-separated commands PATH-shadowed (blocked) for the builder's claude -p
    53	#                       subprocess only (default: codex gemini consult consult.sh marathon-drive.sh
    54	#                       relay-drive.sh). Stops an off-task builder from spawning external models /
    55	#                       recursive marathons. Set empty to disable. (Phase 3.6; not airtight — an
    56	#                       absolute-path call bypasses it; worktree isolation below is the airtight close.)
    57	#   RELAY_WORKTREE_ISOLATION — 1 = run the builder turn in a THROWAWAY git worktree (ROADMAP 3.6 close):
    58	#                       async/background writes land in a tree we delete, never ROOT; `.tick` stays
    59	#                       shared via TICK_REPO_ROOT=ROOT; only the allowlist is copied back. An off-lane
    60	#                       change detected in the worktree → exit 6 (contained AND escalated). Default OFF
    61	#                       (unset) → the prior in-ROOT behaviour, byte-for-byte. Opt-in for unattended/
    62	#                       real-repo runs (the Phase 6 WPCC dogfood gate).
    63	#
    64	# Auth: `claude -p` inherits the credentials stored by `claude login` (~/.claude/). A subscription
    65	# login is sufficient — no API key needed. The binary must be installed and authenticated before
    66	# running headless turns. JSON output schema (--output-format json): usage.{input_tokens,
    67	# cache_read_input_tokens,output_tokens}, total_cost_usd, duration_ms, num_turns.
    68	#
    69	# Tool allowlist split:
    70	#   builder (this shim)                   → "Bash,Read,Edit,Write"  (needs to mutate the artifact)
    71	#   reviewers (codex-turn, gemini-turn)   → "Bash,Read"              (read-only; no write surface)
    72	# rtl_enforce is the real guard either way; the allowlist is a second, tighter layer.
    73	#
    74	#   RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds (default: 900, raised from 600 by
    75	#                          GH-386 so every builder shares one cap; see the Python twin for why the
    76	#                          old value was not a cost control). A hung or
    77	#                          runaway claude CLI is killed after this many seconds; the turn exits 7.
    78	#                          The existing --max-budget-usd / --max-turns API-spend ceilings are
    79	#                          complementary and remain unchanged — wall-clock is the NEW dimension.
    80	#
    81	# Exit: 0 acted/deferred · 3 claude not found · 5 claude failed · 6 off-allowlist edit (reverted) · 7 timeout-killed · 2 usage.
    82	
    83	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    84	# shellcheck source=relay-turn-lib.sh
    85	source "$HERE/relay-turn-lib.sh"
    86	
    87	# Default ROOT to the CWD's git toplevel (the repo the operator is actually driving) so a
    88	# NON-VENDORED run — this shim invoked from outside the target repo, e.g. straight from the swarm
    89	# checkout — roots worktree isolation + artifact copyback at the TARGET, not this shim's own repo
    90	# ($HERE/..). Explicit CLAUDE_TURN_ROOT still wins (fixtures); fall back to $HERE/.. off a git repo.
    91	ROOT="${CLAUDE_TURN_ROOT:-"$(git rev-parse --show-toplevel 2>/dev/null || (cd "$HERE/.." && pwd))"}"
    92	CLAUDE_BIN="${CLAUDE_BIN:-}"
    93	die() { printf 'claude-turn: %s\n' "$*" >&2; exit 2; }
    94	
    95	me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
    96	claude_agent="${CLAUDE_AGENT:-}"
    97	[[ -n "$me" ]] || die "RELAY_AGENT required"
    98	[[ -n "$f" ]] || die "RELAY_FILE required"
    99	[[ -n "$claude_agent" ]] || die "CLAUDE_AGENT required"
   100	
   101	# Dispatch only for the Claude agent; defer otherwise (that window drives its own turn).
   102	if [[ "$me" != "$claude_agent" ]]; then
   103	  printf 'claude-turn: actor %s is not the Claude agent (%s) — deferring (window-driven)\n' "$me" "$claude_agent" >&2
   104	  exit 0
   105	fi
   106	
   107	# Preserve an inherited harness tick root from the orchestrator (e.g. vendored .xyz marathon runs);
   108	# default to this shim's ROOT only when the caller did not already pin TICK_REPO_ROOT. (GH-171)
   109	: "${TICK_REPO_ROOT:=$ROOT}"
   110	export TICK_REPO_ROOT
   111	
   112	# GH-58: Discovery of claude binary + fail-fast
   113	resolved_claude=""
   114	if [[ -n "${CLAUDE_BIN:-}" ]]; then
   115	  if command -v "$CLAUDE_BIN" >/dev/null 2>&1; then
   116	    resolved_claude="$CLAUDE_BIN"
   117	  fi
   118	else
   119	  if command -v claude >/dev/null 2>&1; then
   120	    resolved_claude="claude"
   121	  elif [[ -x "$HOME/.claude/local/claude" ]]; then
   122	    resolved_claude="$HOME/.claude/local/claude"
   123	  fi
   124	fi
   125	
   126	if [[ -z "$resolved_claude" ]]; then
   127	  printf 'claude CLI not found on PATH; set CLAUDE_BIN or use a codex/agy builder\n' >&2
   128	  exit 3
   129	fi
   130	CLAUDE_BIN="$resolved_claude"
   131	
   132	rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"
   133	prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
   134	# GH-68 warn-only: prepend any UNREAD cross-agent dependency-drift heads-up to the turn brief, so a
   135	# builder learns a peer changed a shared surface (kernel/projection/schema) since its last turn. No
   136	# unread drift → empty → prompt unchanged. Never blocks. (decisions/2026-07-01-cross-agent-dep-conflict.md)
   137	drift_brief="$(rtl_drift_brief "$me" "${TICK_REPO_ROOT:-$ROOT}")"
   138	[[ -n "$drift_brief" ]] && prompt="${drift_brief}"$'\n'"${prompt}"
   139	
   140	# GH-172: Claude is a driven builder shim too, so it needs the same pre-launch ownership proof as the
   141	# Codex/Aider/agy shims. Otherwise a "successful" builder edit can still commit while the handed-off
   142	# token remains open under the old owner, and rtl_enforce has no authority to release/done it.
   143	claim_paths="${f#"$ROOT"/}"
   144	if [[ -n "${ALLOW_PATHS:-}" ]]; then
   145	  IFS=',' read -ra _claim_allow <<<"${ALLOW_PATHS}"
   146	  for _ap in "${_claim_allow[@]}"; do
   147	    _ap="${_ap#"${_ap%%[![:space:]]*}"}"
   148	    _ap="${_ap%"${_ap##*[![:space:]]}"}"
   149	    [[ -n "$_ap" ]] && claim_paths="$claim_paths,$_ap"
   150	  done
   151	fi
   152	_tickroot="${TICK_REPO_ROOT:-$ROOT}"; _tickbin="$(rtl_tick_bin "$_tickroot")"
   153	if [[ -x "$_tickbin" ]]; then
   154	  TICK_REPO_ROOT="$_tickroot" "$_tickbin" claim "$t" --agent "$me" --paths "$claim_paths" >/dev/null 2>&1 || true
   155	  _claimer="$(TICK_REPO_ROOT="$_tickroot" "$_tickbin" info "$t" 2>/dev/null | sed -n 's/^claimer:[[:space:]]*//p' | head -n1)"
   156	  if [[ "$_claimer" != "$me" ]]; then
   157	    printf 'claude-turn: could not establish token ownership of %s (claimer=%s, expected %s) — refusing to run so the turn cannot commit with the token open under the old owner; inspect `tick info %s`\n' "$t" "${_claimer:-none}" "$me" "$t" >&2
   158	    exit 5
   159	  fi
   160	  TICK_REPO_ROOT="$_tickroot" "$_tickbin" ping "$t" --agent "$me" >/dev/null 2>&1 || true
   161	fi
   162	
   163	# Transcript: $TMPDIR file, NOT the repo tree (the in-tree log guard deletes it).
   164	# JSON format required: the cost block (usage.input_tokens / total_cost_usd / duration_ms)
   165	# is only emitted with --output-format json.
   166	CLAUDE_LOG="${CLAUDE_LOG:-${TMPDIR:-/tmp}/claude-turn-$$.json}"
   167	
   168	# Model pin: `claude -p` otherwise inherits the operator's AMBIENT model (whatever the interactive
   169	# session / global config selects). A headless builder must pin its own model, or its cost is
   170	# hostage to that ambient choice — a real smoke run on 2026-06-18 inherited `claude-opus-4-8[1m]`
   171	# and blew the $0.50 cap in 4 turns ($0.53) because the ceiling below was sized for Sonnet.
   172	# Default to the spike's model; override with CLAUDE_MODEL for an intentionally heavier builder.
   173	model="${CLAUDE_MODEL:-claude-sonnet-4-6}"
   174	
   175	# Cost ceilings: sized from the M2 authenticated spike (2026-06-17, Sonnet 4.6).
   176	# Real relay turn (minimal fixture): 7 turns, $0.172, 26s wall-clock, 207k cache-read + 1.4k output.
   177	# --max-turns 12: observed 7; headroom for complex builder turns (multi-file edits, retries).
   178	# --max-budget-usd 0.50: observed $0.17; ~3× margin for heavier content. The cache-read bulk
   179	#   (~207k tokens) is cheap; output tokens ($15/M) dominate on complex turns.
   180	# NOTE: these ceilings are valid only for the pinned model — raise --max-budget-usd if CLAUDE_MODEL
relay-automation/consult.sh:40:# (Codex stays `-s read-only` on top of that; agy's writes, if any, are contained by the worktree.)
relay-automation/consult.sh:65:#   CODEX_FLAGS                codex sandbox flags (default: -s read-only)
relay-automation/consult.sh:76:# That is repo-isolation, NOT an OS sandbox — only Codex additionally gets `-s read-only`; a model
relay-automation/consult.sh:78:# "read-only", on purpose.
relay-automation/consult.sh:201:  local out="$1"; read -ra _f <<<"${CODEX_FLAGS:--s read-only}"
relay-automation/consult.sh:209:  local model="unknown" provider="unknown" sandbox="unknown"
relay-automation/consult.sh:213:    sandbox="$(grep -m1 '^sandbox:' "$out" | sed 's/^sandbox:[[:space:]]*//' || true)"
relay-automation/consult.sh:215:      printf '> **ATTESTATION**\n> Model: %s\n> Provider: %s\n> Sandbox: %s\n\n' "${model:-unknown}" "${provider:-unknown}" "${sandbox:-unknown}"
utils/py/codex-turn.py:65:    # GH-263/GH-296: unconditionally grant Codex's sandbox the shared .tick lock dir — both under
utils/py/codex-turn.py:69:    # TICK_REPO_ROOT override still lands in the sandbox allowlist.
utils/py/codex-turn.py:128:        print(f"codex-turn: codex exec exceeded {turn_timeout}s wall-clock cap — killed [{_reason}]", file=sys.stderr)
utils/py/codex-turn.py:131:        print(f"codex-turn: codex exec failed (exit {bounded_rc})", file=sys.stderr)
relay-automation/codex-turn.sh:37:#   CODEX_FLAGS     — autonomy flags for `codex exec` (default: -s workspace-write -c
relay-automation/codex-turn.sh:42:#                     CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox' (removes codex's own
relay-automation/codex-turn.sh:43:#                     sandbox entirely; this repo's containment then relies solely on
relay-automation/codex-turn.sh:133:# CODEX_FLAGS gives the turn enough autonomy to actually write on a fresh device (default sandbox is
relay-automation/codex-turn.sh:134:# read-only); operator-overridable for tighter/looser policies.
relay-automation/codex-turn.sh:135:# GH-106: default adds `-c approval_policy=never` to the sandbox flag so a headless run no longer
relay-automation/codex-turn.sh:137:# workspace-write sandbox restriction (still can't touch outside the workspace) — fully overridable.
relay-automation/codex-turn.sh:158:    # $TICK_REPO_ROOT/.tick is outside Codex's default workspace-write sandbox unless we add it.
relay-automation/codex-turn.sh:168:  # sandbox for free. That assumption breaks in a vendored `.xyz/` install driven from `cd
relay-automation/codex-turn.sh:170:  # OUTSIDE its sandbox and the `tick claim` lock write EPERMs before the turn even starts. Reuse
relay-automation/codex-turn.sh:171:  # the same GH-36 flag here so Codex's sandbox can always reach the shared token lock, whether or
relay-automation/codex-turn.sh:198:  printf 'codex-turn: codex exec exceeded %ss wall-clock cap — killed\n' "$turn_timeout" >&2
relay-automation/codex-turn.sh:200:  printf 'codex-turn: codex exec failed (exit %s)\n' "$bounded_rc" >&2; exit 5
utils/py/rtl.py:229:# Exemptions mirror the bash sweep's documented set: .tick/, .relay-scratch/
utils/py/rtl.py:234:OFFLANE_EXEMPT = (".tick", ".relay-scratch", "relay-system")
utils/py/rtl.py:811:    def enforce(self, task, agent, log_file, model_name):
utils/py/rtl.py:830:        # the bash sweep documents: .tick, .relay-scratch, transcript root).
utils/py/rtl.py:898:    # every read-only consumer (marathon-ls.sh, marathon-live.sh, find-harness.sh) must resolve the
relay-automation/claude-turn.sh:71:#   reviewers (codex-turn, gemini-turn)   → "Bash,Read"              (read-only; no write surface)
relay-automation/agy-turn.sh:71:#       Bash sandbox) `agy -p` exits 0 with EMPTY output. An empty "successful" turn is a FALSE
relay-automation/agy-turn.sh:73:#       Run this shim with the sandbox OFF (like codex; memory: codex-cli-needs-sandbox-disabled).
relay-automation/agy-turn.sh:267:# Guard (a): silent-failure-under-sandbox. agy -p can exit 0 with EMPTY output when its backend is
relay-automation/agy-turn.sh:268:# unreachable (sandboxed network). Treat that as a failed turn, NOT a successful no-op — otherwise an
relay-automation/agy-turn.sh:276:  printf 'agy-turn: agy -p exited 0 but produced NO output — likely a blocked backend (run sandbox-OFF). Failing the turn.\n' >&2
utils/py/agy-turn.py:387:        "output you create must be written under $TMPDIR or the repo's .relay-scratch/ directory — "
utils/py/agy-turn.py:629:        print("agy-turn: agy -p exited 0 but produced NO output — likely a blocked backend (run sandbox-OFF). Failing the turn.", file=sys.stderr)
relay-automation/marathon-closeout.sh:11:# sequence without invoking git or gh, including read-only discovery commands.
relay-automation/marathon-closeout.sh:179:    if [[ -n "$(git status --porcelain)" ]]; then
relay-automation/driver-lock-lib.sh:7:# read-only consumer of the lock (marathon-ls.sh, utils/hq/marathon-live.sh,
utils/py/pi-turn.py:50:    # unset, matching pi-turn.sh and codex/claude-turn.py. pi has no native sandbox — its containment
relay-automation/aider-turn.sh:178:# structurally read-only in Aider even under --yes-always, so this gives full context with no writable
relay-automation/poll.sh:201:  git -C "$GIT_ROOT" status --porcelain -- "${scope[@]}" | grep . >/dev/null && return 1 || return 0
relay-automation/pi-turn.sh:29:# WHY A SEPARATE SHIM (not just another agy-style lane): Pi has no built-in sandbox of its own — same
relay-automation/pi-turn.sh:31:# (RELAY_WORKTREE_ISOLATION=1) + rtl_enforce, not a Pi-native sandbox flag (there isn't one). Unlike
relay-automation/pi-turn.sh:172:# Worktree isolation (opt-in; same wiring as agy-turn.sh). Pi has no sandbox of its own to grant an
relay-automation/xyz-sync.sh:325:  dirty="$(git -C "$HARNESS_ROOT" status --porcelain --untracked-files=normal 2>/dev/null || true)"
relay-automation/new-relay.sh:10:#   (default, reference) — the Setup points at .relay-artifacts/<basename>, the read-only path that
relay-automation/new-relay.sh:122:- Artifact under review: **.relay-artifacts/$art_base** — the read-only path that
relay-automation/marathon-detail.sh:2:# marathon-detail.sh <repo> — preview for ONE repo path (read-only).
relay-automation/marathon-ls.sh:2:# marathon-ls.sh — cross-repo marathon monitor engine (read-only).
relay-automation/marathon-drive.sh:256:# sandboxed observer to read: no process-name inspection is needed. The timer is best-effort; the
relay-automation/marathon-drive.sh:580:  git -C "$root" status --porcelain -- "$git_path" 2>/dev/null | grep -E '^(\?\?|A )' >/dev/null && return 0
relay-automation/marathon-drive.sh:957:# GH-162: peek at prior attempts BEFORE rendering (read-only; lane_attempt_gate in Step 3 still owns
relay-automation/marathon-drive.sh:994:  dirty="$(git -C "$ROOT" status --porcelain 2>/dev/null \
relay-automation/relay-turn-lib.sh:292:  if [[ "${XYZ_TOOL_MODE:-${RELAY_TOOL_MODE:-}}" == "programmatic" ]]; then
relay-automation/relay-turn-lib.sh:293:    if ! command -v sandbox-exec >/dev/null 2>&1 && ! command -v bwrap >/dev/null 2>&1; then
relay-automation/relay-turn-lib.sh:294:      echo "relay-turn-lib: Containment failure (fail-closed): OS sandbox backend (sandbox-exec or bwrap) unavailable for --tool-mode programmatic" >&2
relay-automation/relay-turn-lib.sh:368:  # REVIEWER-turn scoping: a reviewer is near read-only — it only APPENDS findings to the relay file
relay-automation/relay-turn-lib.sh:397:  local _n=() _d=() a _isdir          # normalize to repo-root-relative (git status emits relative)
relay-automation/relay-turn-lib.sh:458:  # read-only into the worktree by rtl_worktree_begin at .relay-artifacts/<basename> — NOT added to
relay-automation/relay-turn-lib.sh:460:  # changes its signature and fails the turn (strict read-only). Empty/unset → no artifact (default).
relay-automation/relay-turn-lib.sh:703:#     READ-ONLY artifact at .relay-artifacts/<basename> — the read-only seed set distinct from the writable
relay-automation/relay-turn-lib.sh:732:  # git worktree add accepts a checkout there and git status ignores it.
relay-automation/relay-turn-lib.sh:800:  # GH-31 / #15: seed the read-only artifact under review so an ISOLATED reviewer can READ it (it is
relay-automation/relay-turn-lib.sh:803:  # edit changes the signature and trips off-lane (strict read-only). NOT in RTL_ALLOW ⇒ never copied back.
relay-automation/relay-turn-lib.sh:826:  mkdir -p "$wt/.relay-scratch"
relay-automation/relay-turn-lib.sh:877:  # so nothing here would ever appear in this worktree's own git status — no exemption needed then.
relay-automation/relay-turn-lib.sh:898:    case "$path" in .relay-scratch|.relay-scratch/|.relay-scratch/*) continue ;; esac
relay-automation/relay-turn-lib.sh:904:    # GH-31 / #15: the read-only artifact seed. Exempt ONLY while unchanged from the seed; a reviewer
relay-automation/relay-turn-lib.sh:905:    # edit changes the .relay-artifacts dir signature → strict-fail as off-lane (read-only enforced,
relay-automation/relay-turn-lib.sh:925:  done < <(git -C "$wt" status --porcelain -z 2>/dev/null)
relay-automation/relay-turn-lib.sh:1037:  local role_note=""
relay-automation/relay-turn-lib.sh:1042:    role_note=' You are the REVIEWER this turn: do NOT edit, create, or run any artifact or source file — ONLY append your graded findings to the relay file. Any other edit will be reverted and fail the turn. When approving, hand the token off with done and set STATUS: Approved.'
relay-automation/relay-turn-lib.sh:1044:  # GH-31 / #15: point the reviewer at the seeded read-only artifact (worktree-relative; it is NOT a
relay-automation/relay-turn-lib.sh:1050:  local scratch_note=" Verification output (probe results, generated JSON, logs) goes under .relay-scratch/ — pre-created for you, exempt from containment, never copied back; scratch files anywhere else in the tree are reverted and FAIL your turn."
relay-automation/relay-turn-lib.sh:1052:  if [[ "${XYZ_TOOL_MODE:-${RELAY_TOOL_MODE:-}}" == "programmatic" ]]; then
relay-automation/relay-turn-lib.sh:1053:    prog_note=" Programmatic tool mode is enabled: diagnostic Python scripts may be executed via script_runner.py with output directed to .relay-scratch/."
relay-automation/relay-turn-lib.sh:1055:  printf 'You are agent %s, taking your turn in a file-based relay. Read %s and follow its embedded "\xe2\x96\xb6 TAKE YOUR TURN" steps for your role. For the %s token ALWAYS use the absolute, env-pinned tick — a bare or ./bin/tick from a worktree/foreign CWD silently no-ops and DEADLOCKS the relay: TICK_REPO_ROOT="%s" "%s". Token sequence: (1) claim it FIRST — claim %s --agent %s --paths %s — the --paths flag is MANDATORY; without it the claim silently fails (prints usage) and your later release errors "task ... is open". (2) ping is optional. (3) when finished, %s. Edit ONLY %s%s.%s%s NEVER run git yourself — no add/commit/push/reset; a self-commit FAILS your whole turn. Do NOT touch any other file. The harness makes the one file-scoped commit for you after you hand off the token. Do NOT run the full project test/gate suite (e.g. validate.sh) yourself — running it can create files that trip containment and DISCARD your whole turn; verify ONLY with the specific test for the file(s) you changed. The harness runs the gate after your turn.%s%s' \
relay-automation/relay-turn-lib.sh:1056:    "$agent" "$f_rel" "$task" "$tickroot" "$tickbin" "$task" "$agent" "$f_rel" "$handoff" "$f_rel" "${csv_rel:+ and: $csv_rel}" "$role_note" "$art_note" "$scratch_note" "$prog_note"
relay-automation/relay-turn-lib.sh:1066:    < <(git -C "$RTL_ROOT" status --porcelain -z 2>/dev/null)
relay-automation/relay-turn-lib.sh:1115:# Deliberately NARROW — this is a room, not an amnesty (same line GH-91 drew for .relay-scratch):
relay-automation/relay-turn-lib.sh:1123:# for inspection) — NOT .relay-scratch/, which rtl_enforce sweeps at end of turn and which would
relay-automation/relay-turn-lib.sh:1138:  printf '%s-turn: SCRATCH RELOCATION (GH-113): untracked root-level %s moved to %s — turn NOT failed. Write scratch under $TMPDIR or .relay-scratch/ instead.\n' \
relay-automation/relay-turn-lib.sh:1154:  case "$p" in .relay-scratch|.relay-scratch/|.relay-scratch/*)
relay-automation/relay-turn-lib.sh:1155:    rm -rf "${RTL_ROOT:?}/.relay-scratch"
relay-automation/relay-turn-lib.sh:1186:# rtl_has_uncited_claim's read-only predicate (used by consult.sh's A4 stamp) — so the two stay in
relay-automation/relay-turn-lib.sh:1244:# GH-178 A4 follow-up (code review on PR #184): read-only predicate reused by consult.sh's advisor
relay-automation/relay-turn-lib.sh:1328:  # `git status` — undo the commit(s) and fail, so off-lane changes can't slip in committed.
relay-automation/relay-turn-lib.sh:1357:  # ignored-file safety belongs to the agent sandbox, tracked as future.
relay-automation/relay-turn-lib.sh:1381:  done < <(git -C "$RTL_ROOT" status --porcelain -z)
relay-automation/relay-turn-lib.sh:1385:  [[ -d "${RTL_ROOT:?}/.relay-scratch" ]] && rm -rf "${RTL_ROOT:?}/.relay-scratch"
relay-automation/relay-turn-lib.sh:1588:  # this instrumentation existed. Gate on `git status --porcelain` (NOT tracked-vs-untracked): a
relay-automation/relay-turn-lib.sh:1590:  # it is untracked BY DESIGN and is meant to survive. `git status --porcelain` naturally excludes
relay-automation/relay-turn-lib.sh:1597:  # absolute path unstripped. Passing that straight to `git status --porcelain --` as a pathspec is a
relay-automation/relay-turn-lib.sh:1602:    _rtl_log_leftover="$(git -C "$RTL_ROOT" status --porcelain -- "$RTL_LOG_REL" 2>/dev/null || true)"
relay-automation/relay-drive.sh:212:  --artifact-file P   Seed an external read-only artifact (a cross-repo PR/diff or any file) into the
relay-automation/relay-drive.sh:402:# GH-31 / #15: a read-only artifact under review. Absolutize it (the shim runs with a different CWD)
   180	    — the same failure direction GH-375's own fix was written to avoid, one branch over.
   181	
   182	    The rule: reclassify ONLY on positive evidence of the TTY cause. If the captured output already
   183	    says agy could not open a TTY, the timeout carries no more information about auth than the fast
   184	    failure did — on a platform where `whoami` can never succeed headlessly, a timeout is just a
   185	    slower spelling of the same thing. Anything else — an interactive login prompt, an unfamiliar
   186	    error, or NO output at all — stays fatal, which keeps the branch's original purpose intact for a
   187	    genuine hang on a login prompt.
   188	
   189	    Deliberately narrower than "a timeout is unverifiable". That broader rule would also swallow the
   190	    real hang this branch exists to catch, and silence is exactly the shape a login prompt waiting on
   191	    stdin produces.
   192	    """
   193	    try:
   194	        with open(out_file, "r", encoding="utf-8", errors="replace") as f:
   195	            output = f.read()
   196	    except OSError:
   197	        output = ""
   198	    for raw in output.splitlines():
   199	        line = raw.strip()
   200	        if any(m in line.lower() for m in AGY_AUTH_TTY_MARKERS):
   201	            return ("unverifiable",
   202	                    "agy could not open a TTY and then exceeded the probe timeout, so auth was not "
   203	                    f"verified (the timeout is the same TTY failure, slower): {line}")
   204	    # agy 1.1.16: the diagnostic is control codes, not prose. See agy_tui_takeover_only — a mute
   205	    # terminal takeover is the TTY cause, so it belongs with the case above, not with silence.
   206	    if agy_tui_takeover_only(output):
   207	        return ("unverifiable",
   208	                "the probe emitted a terminal-takeover escape sequence and no readable output, then "
   209	                "exceeded its timeout — agy fell through to its interactive TUI, which cannot run "
   210	                "headless, so auth was not verified either way")
   211	    return ("failed", "the probe timed out with no TTY diagnostic, which is the shape of a genuine "
   212	                      "hang on an interactive login prompt")
   213	
   214	
   215	def split_allow_paths(allow_paths):
   216	    paths = []
   217	    for path in (allow_paths or "").split(","):
   218	        path = path.strip()
   219	        if path:
   220	            paths.append(path)
   221	    return paths
   222	
   223	
   224	# GH-654 — mirror of rtl_worktree_end's sweep, just far enough to NAME the
   225	# candidates. The bash function was born silent (1f0a5bf1, initial public
   226	# release): the general rtl_in_allow-fail branch sets RTL_WT_OFFLANE=1 with no
   227	# path record and destroys the only copy of the evidence. This reports every
   228	# porcelain path that would fail the allowlist so the verdict is diagnosable.
   229	# Exemptions mirror the bash sweep's documented set: .tick/, .relay-scratch/
   230	# (GH-91), and the transcript root top dir "relay-system" (GH-266, the default
   231	# rtl_transcript_root basename; only when XYZ_ARCHIVE_ROOT is unset). Deliberate
   232	# approximation: exotic bash corners (rename second fields, artifact-signature
   233	# checks) resolve toward REPORTING, never toward silence.
   234	OFFLANE_EXEMPT = (".tick", ".relay-scratch", "relay-system")
   235	
   236	
   237	def normalized_allow_csv(allow_paths):
   238	    """GH-654 root cause #2 — rtl_init splits allow_csv with bare IFS=',': no
   239	    trim. marathon-drive renders the plan's `artifact:` string verbatim, and a
   240	    conventionally-formatted "a, b, c" therefore put " b" and " c" into
   241	    RTL_ALLOW; the leading space can never match worktree-relative porcelain,
   242	    so every artifact AFTER THE FIRST was invisible to containment and its
   243	    edit destroyed the turn. Single-artifact plans never tripped it, which is
   244	    why it survived since 1f0a5bf1. The Python layer trims before handing the
   245	    CSV to the bridge (tick's own claim parser already trims, bin/tick:100 —
   246	    which is exactly why the divergence hid so long)."""
   247	    return ",".join(split_allow_paths(allow_paths))
   248	
   249	
   250	def offlane_candidates(wt_path, allow_paths, relay_file):
   251	    try:
   252	        proc = subprocess.run(
   253	            ["git", "-C", wt_path, "status", "--porcelain", "-z"],
   254	            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
   255	            timeout=15, check=False,
   256	        )
   257	    except Exception:
   258	        return []
   259	    entries = proc.stdout.decode("utf-8", "replace").split("\0")
   260	    allow = split_allow_paths(allow_paths)
   261	    allow.append(relay_file)
   262	    # GH-654 follow-up: the shims pass the relay file ABSOLUTE while porcelain
   263	    # is worktree-relative. Normalize ABSOLUTE entries against the worktree;
   264	    # relative entries are already root-relative (same layout) and must not be
   265	    # touched — abspath would resolve them against this process's cwd.
   266	    normalized = []
   267	    for entry in allow:
   268	        entry = entry.strip().rstrip("/")
   269	        if not entry:
   270	            continue
   271	        if os.path.isabs(entry):
   272	            try:
   273	                rel = os.path.relpath(entry, os.path.abspath(wt_path))
   274	            except ValueError:
   275	                rel = None
   276	            entry = rel if (rel and not rel.startswith("..")) else entry
   277	        normalized.append(entry)
   278	    allow = normalized
   279	    found, i = [], 0
   280	    while i < len(entries):
   281	        entry = entries[i]
   282	        i += 1
   283	        if not entry or len(entry) < 4:
   284	            continue
   285	        xy, path = entry[:2], entry[3:]
   500	    setup fails (`sys.exit(5)`), containment rejects the turn (`sys.exit(6)`), a derivation call
   501	    fail-fasts, an exception escapes. On any of those the claim simply stays held.
   502	
   503	    That is not a cosmetic leak, because an agent may hold only two (MAX_ACTIVE_CLAIMS_PER_AGENT).
   504	    TWO such failures wedge that agent permanently, and the wedge is self-inflicted, does not clear
   505	    itself, and reports itself as a problem with the NEXT token rather than with the earlier turns.
   506	    GH-432 fixed the neighbouring half — a failed *agent* now reaches enforce — but the paths above
   507	    never consult the agent's result at all, so they were untouched by it.
   508	
   509	    IDEMPOTENT BY CONSTRUCTION, and that is the load-bearing property. It re-reads `tick info` and
   510	    releases only if the task is STILL claimed by us at exit. After a normal turn the token has
   511	    already been released to the peer (GH-67 handoff) or marked done, so this sees `status: open` /
   512	    `done` and does nothing — it cannot clobber a handoff a successful turn just made. Blanket
   513	    releasing would.
   514	
   515	    Deliberately a RELEASE and not a `reap`. Reaping is the watchdog's authority path for someone
   516	    else's dead claim; this process is the legitimate owner cleaning up after itself, and the
   517	    distinction is worth keeping in the event log. Equally deliberately, nothing here auto-reaps on a
   518	    cap error: silently stealing a claim would trade a loud stall for a race against an agent that is
   519	    genuinely busy (the issue's own non-goal).
   520	
   521	    SIGKILL and a host panic are out of reach — atexit cannot run — and stay the watchdog's job.
   522	    """
   523	    def _release_if_still_held():
   524	        try:
   525	            info = subprocess.run([tick_bin, "info", task], env=tick_env,
   526	                                  capture_output=True, text=True)
   527	        except Exception:
   528	            return
   529	        status = claimer = ""
   530	        for line in info.stdout.splitlines():
   531	            if line.startswith("status:"):
   532	                status = line.split(":", 1)[1].strip()
   533	            elif line.startswith("claimer:"):
   534	                claimer = line.split(":", 1)[1].strip()
   535	        if status != "claimed" or claimer != agent:
   536	            return
   537	        res = subprocess.run([tick_bin, "release", task, "--agent", agent],
   538	                             env=tick_env, capture_output=True, text=True)
   539	        if res.returncode == 0:
   540	            # Say so. A silent cleanup of a leak is how the leak stayed unmeasured: the operator
   541	            # needs to know this turn ended without handing its token on properly.
   542	            print(f"{tool_name}: released the claim on {task} that this turn would otherwise have "
   543	                  f"left held — the turn ended without reaching its own token handoff (GH-409)",
   544	                  file=sys.stderr)
   545	        else:
   546	            detail = ((res.stdout or "") + (res.stderr or "")).strip()
   547	            print(f"{tool_name}: could not release the claim on {task} at exit ({detail}) — "
   548	                  f"`tick reap {agent} --task {task}` will clear it", file=sys.stderr)
   549	
   550	    atexit.register(_release_if_still_held)
   551	
   552	# ASCII-only slug alphabet — mirrors the Bash `tr -c 'A-Za-z0-9._-' '_'` sanitizer exactly. Python's
   553	# str.isalnum() would also pass Unicode letters/digits (e.g. `é`), diverging from the Bash contract.
   554	_SLUG_SAFE = frozenset("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-")
   555	
   556	def _ascii_slug(s):
   557	    return "".join(c if c in _SLUG_SAFE else "_" for c in s)
   558	
   559	def _rtl_repo_slug(target_root):
   560	    # Mirror Bash rtl_repo_slug: origin remote basename, else target dir basename, sanitized to a SAFE
   561	    # single path segment ([A-Za-z0-9._-]; never empty, never "."/"..", never leading "-").
   562	    url = ""
   563	    try:
   564	        url = subprocess.check_output(["git", "-C", target_root, "remote", "get-url", "origin"],
   565	                                      stderr=subprocess.DEVNULL).decode("utf-8").strip()
   566	    except Exception:
   567	        url = ""
   568	    while url.endswith("/"):
   569	        url = url[:-1]
   570	    if url.endswith(".git"):
   571	        url = url[:-4]
   572	    while url.endswith("/"):
   573	        url = url[:-1]
   574	    slug = ""
   575	    if url:
   576	        slug = url.rsplit("/", 1)[-1].rsplit(":", 1)[-1]   # strip path AND scp-style host: prefix
   577	    if not slug:
   578	        slug = os.path.basename(target_root) or ""
   579	    slug = _ascii_slug(slug or "repo")
   580	    while slug.startswith("-"):
   581	        slug = slug[1:]
   582	    if slug in ("", ".", ".."):
   583	        slug = "repo"
   584	    return slug
   585	
   586	def _rtl_transcript_root(target_root, quiet=False):
   587	    # Mirror Bash rtl_transcript_root: <root>/relay-system on the common path; when XYZ_ARCHIVE_ROOT is
   588	    # set, validate it (ABSOLUTE, exists, is a git repo — Model A) and namespace as
   589	    # <archive>/relay-system/<repo-slug>. Returns None on an invalid archive so the caller (rtl_default_log)
   590	    # falls back to $TMPDIR, exactly as the Bash `... || fallback` does. quiet=True mirrors Bash callers
   591	    # that redirect the resolver's stderr (rtl_default_log) — direct callers keep the diagnostics.
   592	    def _warn(msg):
   593	        if not quiet:
   594	            print(msg, file=sys.stderr)
   595	    target_root = (target_root or "").rstrip("/")
   596	    ar = os.environ.get("XYZ_ARCHIVE_ROOT", "")
   597	    if not ar:
   598	        return f"{target_root}/relay-system"
   599	    if not os.path.isabs(ar):
   600	        _warn(f"rtl_transcript_root: XYZ_ARCHIVE_ROOT must be an ABSOLUTE path, got: {ar}")
   601	        return None
   602	    if not os.path.isdir(ar):
   603	        _warn(f"rtl_transcript_root: XYZ_ARCHIVE_ROOT does not exist (or is not a directory): {ar}")
   604	        return None
   605	    if subprocess.run(["git", "-C", ar, "rev-parse", "--git-dir"],
   606	                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
   607	        _warn(f"rtl_transcript_root: XYZ_ARCHIVE_ROOT is not a git repo (Model A requires a committed archive): {ar}")
   608	        return None
   609	    return f"{ar}/relay-system/{_rtl_repo_slug(target_root)}"
   610	
   611	def non_durable_conf_path():
   612	    """The ONE registry of storage this harness will not trust with evidence (GH-388).
   613	
   614	    Deliberately a file both lanes read at runtime, not a constant duplicated per language — see the
   615	    conf's own header. `relay-automation/durable-log-lib.sh` is the Bash reader of this same file.
   616	    """
   617	    here = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
   618	    return os.path.join(here, "relay-automation", "non-durable-log-roots.conf")
   619	
   620	def _realish_path(path):
   621	    # Canonicalize without requiring the path to exist — the log file is usually about to be created.
   622	    # os.path.realpath resolves what it can and leaves the rest, which is exactly the behaviour
   623	    # wanted here: on macOS /tmp is a symlink to /private/tmp, and a logical-form comparison alone
   624	    # would let the same directory through under its other name.
   625	    if not os.path.isabs(path):
   626	        path = os.path.abspath(path)
   627	    return os.path.realpath(path).rstrip("/") or "/"
   628	
   629	def non_durable_reason(path):
   630	    """The non-durable prefix `path` falls under, or "" if it is durable (GH-388)."""
   631	    if not path:
   632	        return ""
   633	    real = _realish_path(path)
   634	
   635	    def _match(prefix):
   636	        prefix = _realish_path(prefix) if prefix else ""
   637	        if not prefix:
   638	            return False
   639	        return real == prefix or real.startswith(prefix.rstrip("/") + "/")
   640	
   641	    # TMPDIR is a value, not a literal the conf file can hold. Checked first so a relocated TMPDIR is
   642	    # caught even when it points somewhere the static list never anticipated.
   643	    tmpdir = os.environ.get("TMPDIR", "")
   644	    if tmpdir and _match(tmpdir):
   645	        return _realish_path(tmpdir)
   646	
   647	    try:
   648	        with open(non_durable_conf_path(), "r", encoding="utf-8") as f:
   649	            lines = f.read().splitlines()
   650	    except OSError:
   651	        return ""
   652	    for raw in lines:
   653	        entry = raw.split("#", 1)[0].strip()
   654	        if entry and _match(entry):
   655	            return entry.rstrip("/")
   656	    return ""
   657	
   658	def path_is_durable(path):
   659	    return not non_durable_reason(path)
   660	
   661	def rtl_default_log(root, tool, task):
   662	    """Persistent turn-transcript path under <transcript-root>/logs/<date>/ (GH-161).
   663	
   664	    GH-388: this used to fall back to $TMPDIR **with the diagnostic suppressed** (`quiet=True`, then
   665	    `return fallback` on any failure). A misconfigured `XYZ_ARCHIVE_ROOT` therefore relocated every
   666	    turn transcript into the one directory a reboot erases, and said nothing — so the evidence was
   667	    already gone by the time anyone had a reason to look for it, and nothing in the run had indicated
   668	    a choice was being made at all.
   669	
   670	    It now resolves a durable root or REFUSES, before the turn launches. Refusing costs a turn that
   671	    has not started; the old behaviour cost the record of a turn that had. Adding a warning while
   672	    still writing to volatile storage was considered and rejected in the issue's own review: the logs
   673	    would still be destroyed, and the message would only mean someone could have known.
   674	
   675	    The resolver's diagnostics are no longer swallowed either — `quiet=False` — because the reason
   676	    the root failed to resolve (not absolute / does not exist / not a git repo) is the entire content
   677	    of the fix from the operator's side.
   678	    """
   679	    base = _rtl_transcript_root(root, quiet=False)
   680	    if not base:
   760	RC=$?
   761	
   762	vars=$(compgen -v | grep '^RTL_' || true)
   763	if [ -n "$vars" ]; then
   764	  declare -p $vars > {state_tmp} 2>/dev/null
   765	  mv {state_tmp} {state}
   766	fi
   767	
   768	exit $RC
   769	"""
   770	        env = dict(os.environ)
   771	        env["TICK_REPO_ROOT"] = os.environ.get("TICK_REPO_ROOT", self.root)
   772	        # Never sys.exit() here: callers (before/enforce/worktree_begin) must be
   773	        # able to inspect a non-zero return code and route it (containment exit 6,
   774	        # worktree-failure exit 5). Fail-fast for the must-succeed derivation calls
   775	        # lives in _run_checked, one layer up.
   776	        return subprocess.run(["bash", "-c", script], capture_output=capture, text=True, env=env)
   777	
   778	    def _run_checked(self, cmd_str, capture=True):
   779	        # For derivation calls (artifact/prompt/drift) whose failure means the turn
   780	        # cannot proceed: preserve the original fail-fast behavior explicitly, at the
   781	        # call site rather than buried in the shared runner.
   782	        res = self._run_rtl(cmd_str, capture=capture)
   783	        if res.returncode != 0:
   784	            print(f"rtl: relay-turn-lib call failed (exit {res.returncode})", file=sys.stderr)
   785	            sys.exit(res.returncode)
   786	        return res
   787	
   788	    def get_artifact(self):
   789	        res = self._run_checked("echo -n \"${RTL_ARTIFACT:-}\"")
   790	        return res.stdout.strip()
   791	
   792	    def turn_prompt(self, agent, task, peer):
   793	        cmd = f"rtl_turn_prompt {shlex.quote(agent)} {shlex.quote(self.relay_file)} {shlex.quote(task)} {shlex.quote(normalized_allow_csv(self.allow_paths))} {shlex.quote(peer)}"
   794	        res = self._run_checked(cmd)
   795	        return res.stdout.strip()
   796	
   797	    def drift_brief(self, agent, tick_repo_root):
   798	        # GH-374: the tick event registry can be shared by a harness and a foreign turn root.
   799	        # Pass the driven repository explicitly so the Bash core filters stale cross-repo surfaces
   800	        # against that repository's committed HEAD, matching the direct Bash-shim path.
   801	        turn_root = os.environ.get("RELAY_TARGET_ROOT", self.root)
   802	        cmd = (f"rtl_drift_brief {shlex.quote(agent)} {shlex.quote(tick_repo_root)} "
   803	               f"{shlex.quote(turn_root)}")
   804	        res = self._run_checked(cmd)
   805	        return res.stdout.strip()
   806	        
   807	    def before(self):
   808	        res = self._run_rtl("rtl_before", capture=False)
   809	        return res.returncode
   810	        
   811	    def enforce(self, task, agent, log_file, model_name):
   812	        cmd = f"rtl_enforce {shlex.quote(task)} {shlex.quote(agent)} {shlex.quote(log_file)} {shlex.quote(model_name)}"
   813	        res = self._run_rtl(cmd, capture=False)
   814	        return res.returncode
   815	        
   816	    def worktree_begin(self):
   817	        # prints the worktree path to stdout
   818	        res = self._run_rtl("rtl_worktree_begin")
   819	        if res.returncode == 0:
   820	            return res.stdout.strip()
   821	        return None
   822	        
   823	    def worktree_end(self, wt_path):
   824	        # GH-654: the bash sweep answers a bare yes/no and then destroys the
   825	        # worktree, so a false positive was undiagnosable after the fact — three
   826	        # marathon turns were lost to an off-lane verdict nobody could inspect.
   827	        # Name the evidence BEFORE the verdict runs. Diagnostic only: the bash
   828	        # verdict below stays authoritative, and this mirror deliberately
   829	        # over-reports rather than stays silent (it skips only the exemptions
   830	        # the bash sweep documents: .tick, .relay-scratch, transcript root).
   831	        try:
   832	            for cand in offlane_candidates(wt_path, self.allow_paths, self.relay_file):
   833	                sys.stderr.write("rtl: GH-654 off-lane candidate: %s\n" % cand)
   834	            sys.stderr.write("rtl: GH-654 allowlist: [%s] relay_file: %s\n" % (
   835	                ", ".join(split_allow_paths(self.allow_paths)), self.relay_file))
   836	        except Exception:
   837	            pass  # diagnostics must never fail the turn they describe
   838	        cmd = f"""
   839	rtl_worktree_end {shlex.quote(wt_path)}
   840	echo -n "${{RTL_WT_OFFLANE:-0}}"
   841	"""
   842	        res = self._run_rtl(cmd)
   843	        return res.stdout.strip() == "1"
   844	
   845	
   846	# GH-410: ADVISORY ONLY — never a verdict.
   847	#
   848	# `worktree_end` above is the containment verdict: it diffs the worktree's own git state, so it
   849	# observes writes that actually happened, and all five turn shims exit 6 on it identically.
   850	#
   851	# This function answers a strictly weaker question — does the transcript NAME the real repo root —
   852	# and the two diverge in both directions. An agent that quietly touched the real tree without naming
   853	# it is not detected here; an agent that merely cites an absolute path in a finding is. Measured
   854	# (#410): two phases in one run, same builder and same isolation settings, where the one with TEN
   855	# repo-root mentions was Approved and the one with NINE failed three consecutive times.
   856	#
   857	# It used to fail the turn, which discarded completed reviews. Three exemption patches were spent
   858	# trying to make it precise (#183 `TICK_REPO_ROOT=`, #187 `file://` and `](`) and a fourth shape was
   859	# still outstanding: the harness's own retry preamble renders absolute paths into the relay file, so
   860	# an agent following instructions writes the trigger into its own transcript.
   861	#
   862	# Do NOT re-promote this to a verdict without first making reads observable. If that ever happens,
   863	# the seeding in marathon_drive's retry preamble has to be fixed first.
   864	def narration_mentions_root(log_path, root):
   865	    """Count transcript lines naming `root`, ignoring known-benign shapes. (count, first_line).
   866	
   867	    Returns (0, None) when the log is missing, empty, or names nothing. The exemptions are kept only
   868	    to stop the advisory from being pure noise — they are no longer load-bearing, because nothing
   869	    fails on this result.
   870	    """
   871	    if not root or not log_path or not os.path.exists(log_path):
   872	        return 0, None
   873	    try:
   874	        if os.path.getsize(log_path) == 0:
   875	            return 0, None
   876	    except OSError:
   877	        return 0, None
   878	
   879	    count, first = 0, None
   880	    try:
   881	        with open(log_path, "r", errors="replace") as fh:
   882	            for line in fh:
   883	                if line.startswith("[trace] "):
   884	                    continue
   885	                if "TICK_REPO_ROOT=" in line or "file://" in line or "](" in line:
   886	                    continue
   887	                if root in line:
   888	                    count += 1
   889	                    if first is None:
   890	                        first = line.strip()
   891	    except OSError:
   892	        return 0, None
   893	    return count, first
   894	
   895	def driver_lock_path(root):
   896	    # GH-448: the ONE shared resolver for the relay-driver lock path, matching the DRIVER's own
   897	    # write-side resolution (marathon_drive.py / marathon-drive.sh, relay_drive.py / relay-drive.sh) —
   898	    # every read-only consumer (marathon-ls.sh, marathon-live.sh, find-harness.sh) must resolve the
   899	    # SAME path or it probes a location the driver never writes and reports a live run as idle.
   900	    #   .git is a directory  -> <root>/.git/relay-driver.lock                (normal clone)
     1	#!/usr/bin/env python3
     2	import os
     3	import sys
     4	import tempfile
     5	import subprocess
     6	import shlex
     7	from rtl import RelayTurnLib, claim_task_or_exit, rtl_default_log, resolve_turn_root
     8	from turn_diagnostics import TurnDiagnostics
     9	
    10	def die(msg):
    11	    print(f"codex-turn: {msg}", file=sys.stderr)
    12	    sys.exit(2)
    13	
    14	def default_codex_flags():
    15	    # GH-106: mirror the Bash default so a headless Codex turn never hangs on an
    16	    # interactive approval prompt while still staying inside workspace-write.
    17	    return os.environ.get("CODEX_FLAGS", "-s workspace-write -c approval_policy=never").split()
    18	
    19	def main():
    20	    if "-h" in sys.argv[1:] or "--help" in sys.argv[1:]:
    21	        print("Usage: codex-turn.py")
    22	        print("Required environment variables: RELAY_AGENT, RELAY_FILE, RELAY_TASK")
    23	        sys.exit(0)
    24	
    25	    xyz_root = os.environ.get("XYZ_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    26	    root = resolve_turn_root(os.environ.get("CODEX_TURN_ROOT"), xyz_root)
    27	    codex_bin = os.environ.get("CODEX_BIN", "codex")
    28	
    29	    me = os.environ.get("RELAY_AGENT", "")
    30	    f = os.environ.get("RELAY_FILE", "")
    31	    t = os.environ.get("RELAY_TASK", "RELAY-TURN")
    32	    codex_agent = os.environ.get("CODEX_AGENT", "")
    33	
    34	    if not me: die("RELAY_AGENT required")
    35	    if not f: die("RELAY_FILE required")
    36	    if not codex_agent: die("CODEX_AGENT required")
    37	
    38	    if me != codex_agent:
    39	        print(f"codex-turn: actor {me} is not the Codex agent ({codex_agent}) — deferring (window-driven)", file=sys.stderr)
    40	        sys.exit(0)
    41	
    42	    allow_paths = os.environ.get("ALLOW_PATHS", "")
    43	    peer = os.environ.get("RELAY_PEER", "")
    44	    
    45	    # GH-161: default the transcript to a PERSISTENT path under relay-system/logs/<date>/ (mirrors
    46	    # Bash codex-turn.sh) and export RTL_LOG BEFORE the first rtl call — so the Bash rtl_init/enforce
    47	    # traces (fine-grained under RTL_TRACE=1, unconditional log_always) land in this transcript.
    48	    codex_log = os.environ.get("CODEX_LOG") or rtl_default_log(root, "codex-turn", t)
    49	    os.environ["RTL_LOG"] = codex_log
    50	
    51	    rtl = RelayTurnLib(root, xyz_root, f, allow_paths)
    52	    
    53	    prompt = rtl.turn_prompt(me, t, peer)
    54	    tick_repo_root = os.environ.get("TICK_REPO_ROOT", root)
    55	    drift_brief = rtl.drift_brief(me, tick_repo_root)
    56	    if drift_brief:
    57	        prompt = drift_brief + "\n" + prompt
    58	
    59	    # GH-165: mirror the Bash shim — establish ownership of the specific handed-off
    60	    # token before launching Codex, so rtl.enforce's GH-67 post-commit handoff has
    61	    # real authority to release/done instead of warning on a non-owner token.
    62	    tick_repo_root, _tick_bin = claim_task_or_exit(root, xyz_root, f, allow_paths, t, me, "codex-turn")
    63	
    64	    cflags = default_codex_flags()
    65	    # GH-263/GH-296: unconditionally grant Codex's sandbox the shared .tick lock dir — both under
    66	    # worktree isolation (workdir=throwaway worktree) and the isolation=0 default (workdir=ROOT,
    67	    # which in a same-repo vendored .xyz/ install can still differ from tick_repo_root). Mirrors
    68	    # codex-turn.sh's codex_extra_flags. Built off tick_repo_root (not root), so an explicit
    69	    # TICK_REPO_ROOT override still lands in the sandbox allowlist.
    70	    codex_extra_flags = ["--add-dir", f"{tick_repo_root}/.tick"]
    71	
    72	    rtl.before()
    73	
    74	        # GH-320: this default MUST match the Bash twin's `${RELAY_TURN_TIMEOUT_S:-N}` and the
    75	    # ceiling its header documents. It read 300 while the twin said 900, and since Python is the
    76	    # executing lane every turn was silently capped at a fraction of the documented budget —
    77	    # observed live as an exit-7 kill on a review turn that had 900s on paper.
    78	    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 900))
    79	
    80	    wt = ""
    81	    run_cwd = root
    82	
    83	    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
    84	        wt = rtl.worktree_begin()
    85	        if wt:
    86	            run_cwd = wt
    87	            print(f"codex-turn: worktree isolation ON ({wt})", file=sys.stderr)
    88	            os.environ["TICK_REPO_ROOT"] = tick_repo_root
    89	        else:
    90	            print("codex-turn: worktree isolation requested but `git worktree add` failed — failing turn", file=sys.stderr)
    91	            sys.exit(5)
    92	
    93	    codex_env = dict(os.environ)
    94	    if os.environ.get("CODEX_ALLOW_API_KEY", "0") != "1":
    95	        codex_env.pop("OPENAI_API_KEY", None)
    96	
    97	    cmd = [codex_bin, "exec"] + cflags + codex_extra_flags + [prompt]
    98	    
    99	    bounded_rc = 0
   100	    # Sample the turn while it runs so an exit-7 timeout can be attributed to a
   101	    # cause. subprocess.run reaps the child before raising, so nothing can be
   102	    # probed after the fact — see turn_diagnostics.
   103	    diag = TurnDiagnostics(worktree=run_cwd)
   104	    diag.start()
   105	    try:
   106	        # GH-161: append (not truncate) — rtl_init already wrote its decision-trace line into codex_log
   107	        # via the exported RTL_LOG; a truncating open here would silently wipe it (mirrors codex-turn.sh:170).
   108	        with open(codex_log, "a") as log_f:
   109	            subprocess.run(cmd, env=codex_env, cwd=run_cwd, timeout=turn_timeout, stdout=log_f, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, check=True)
   110	    except subprocess.TimeoutExpired:
   111	        bounded_rc = 7
   112	    except subprocess.CalledProcessError as e:
   113	        bounded_rc = e.returncode
   114	    except Exception as e:
   115	        bounded_rc = 5
   116	    finally:
   117	        diag.stop()
   118	
   119	    if wt:
   120	        off_lane = rtl.worktree_end(wt)
   121	        if off_lane:
   122	            print("codex-turn: codex made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)", file=sys.stderr)
   123	            sys.exit(6)
   124	
   125	    if bounded_rc == 7:
   126	        # Exit code stays 7 for callers; the reason names WHY.
   127	        _reason, _detail = diag.classify()
   128	        print(f"codex-turn: codex exec exceeded {turn_timeout}s wall-clock cap — killed [{_reason}]", file=sys.stderr)
   129	        print(f"codex-turn: timeout attribution: {_detail}", file=sys.stderr)
   130	    elif bounded_rc != 0:
   131	        print(f"codex-turn: codex exec failed (exit {bounded_rc})", file=sys.stderr)
   132	
   133	    # GH-432: a failed turn still reaches rtl_enforce, so its work is committed and its token handed
   134	    # off instead of leaking. See utils/py/claude-turn.py for the full rationale. Exit 5 is unchanged.
   135	    rc = rtl.enforce(t, me, codex_log, "codex")
   136	
   137	    try:
   138	        from harness_turn_logger import HarnessTurnLogger
   139	        with HarnessTurnLogger(
   140	            harness_id="codex",
   141	            shim="codex-turn.py",
   142	            task_scope=t,
   143	            # GH-346 Phase 0: CODEX_MODEL is read nowhere else in this shim — codex is never
   144	            # given a --model flag, so a hardcoded openai/gpt-5-codex here recorded a model this
   145	            # shim never selected. Pass None when unset and let device_config's resolver answer.
   146	            model_id=os.environ.get("CODEX_MODEL") or None,
   147	            gateway=os.environ.get("CODEX_GATEWAY", "openai"),
   148	            reasoning_effort=os.environ.get("CODEX_REASONING_EFFORT", "high"),
   149	            # GH-346: was `flags`, which is bound nowhere in this file. Evaluating the argument
   150	            # raised NameError, the `except Exception: pass` below swallowed it, and this gateway
   151	            # therefore wrote NO telemetry row on any turn, for the life of the shim. The real
   152	            # variable is cflags (:64).
   153	            cli_flags=cflags,
   154	            repo_root=xyz_root,
   155	        ) as logger:
   156	            logger.exit_code = bounded_rc or rc
   157	    except Exception as _telemetry_exc:
   158	        # GH-346: this used to be a bare `pass`. Three shims passed an undefined name as
   159	        # cli_flags, raised NameError here, and silently wrote NO telemetry row for the entire
   160	        # life of the shim -- a telemetry system that fails closed and says nothing. Still
   161	        # non-fatal (a turn must never fail because logging did), but never again invisible.
   162	        print(f"codex-turn: telemetry not recorded: %r" % (_telemetry_exc,), file=sys.stderr)
   163	
   164	    if bounded_rc == 7:
   165	        sys.exit(7)
   166	    if bounded_rc != 0:
   167	        sys.exit(5)
   168	
   169	    sys.exit(rc)
   170	
   171	if __name__ == "__main__":
   172	    main()

exec
/bin/zsh -lc "rg -n \"RELAY_WORKTREE_ISOLATION|CODEX_FLAGS|workspace-write|read-only|AGY_FLAGS|skip-permissions\" utils/py/relay_drive.py relay-automation/relay-drive.sh relay-automation/marathon-agent.sh utils/py/*.py relay-automation/*.sh | sed -n '1,260p'
rg -n \"rtl_is_containment_ignored|RTL_CONTAINMENT|ignored\" relay-automation/relay-turn-lib.sh utils/py/rtl.py test/gh91-relay-scratch.sh
nl -ba test/gh91-relay-scratch.sh | sed -n '1,180p'
nl -ba PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md | sed -n '1,180p'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-93733-mu26k550
 succeeded in 0ms:
utils/py/_marathon_plan.py:1389:        o.append("- If the lane's allowlist includes filesystem-touching `test/*.sh`, treat those tests as read-only specs in-turn; the outer harness gate verifies them after the turn, outside the isolated worktree.")
utils/py/consult.py:625:                cflags = os.environ.get("CODEX_FLAGS", "-s read-only").split()
utils/py/consult.py:637:                cmd = [agy_bin, "--dangerously-skip-permissions", "--print-timeout", f"{timeout_s}s", "-p", full_prompt]
utils/py/agy-turn.py:406:    agy_args = ["--dangerously-skip-permissions", "--print-timeout", f"{turn_timeout}s"]
utils/py/agy-turn.py:411:    aflags = os.environ.get("AGY_FLAGS", "").split()
utils/py/agy-turn.py:426:    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
utils/py/agy-turn.py:654:            cli_flags=os.environ.get("AGY_FLAGS", "").split(),
utils/py/board_sync.py:1375:    pp = sub.add_parser("policy-preview", help="write a read-only saved-policy preview")
relay-automation/relay-drive.sh:212:  --artifact-file P   Seed an external read-only artifact (a cross-repo PR/diff or any file) into the
relay-automation/relay-drive.sh:309:# shims (codex/agy/claude-turn.sh) read RELAY_WORKTREE_ISOLATION; exporting it here makes every
relay-automation/relay-drive.sh:310:# DRIVEN turn contained by default. Opt out per run with RELAY_WORKTREE_ISOLATION=0. (Direct/attended
relay-automation/relay-drive.sh:312:: "${RELAY_WORKTREE_ISOLATION:=1}"; export RELAY_WORKTREE_ISOLATION
relay-automation/relay-drive.sh:327:  [[ "${RELAY_WORKTREE_ISOLATION:-1}" != 0 ]] || return 0
relay-automation/relay-drive.sh:345:    printf '  RELAY_WORKTREE_ISOLATION=1 runs the turn-taker in a worktree at HEAD, but its own\n' >&2
relay-automation/relay-drive.sh:348:    printf '  RELAY_WORKTREE_ISOLATION=0 if you want to rule out isolation entirely; neither is required.\n' >&2
relay-automation/relay-drive.sh:354:    printf '  first, or re-run with RELAY_WORKTREE_ISOLATION=0.\n' >&2
relay-automation/relay-drive.sh:402:# GH-31 / #15: a read-only artifact under review. Absolutize it (the shim runs with a different CWD)
relay-automation/relay-drive.sh:412:  [[ "$RELAY_WORKTREE_ISOLATION" != 0 ]] || \
relay-automation/relay-drive.sh:413:    printf 'relay-drive: WARNING — --artifact-file needs worktree isolation to seed the artifact; with RELAY_WORKTREE_ISOLATION=0 the reviewer will not see it.\n' >&2
utils/py/commandcode-turn.py:72:    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
utils/py/codex-turn.py:16:    # interactive approval prompt while still staying inside workspace-write.
utils/py/codex-turn.py:17:    return os.environ.get("CODEX_FLAGS", "-s workspace-write -c approval_policy=never").split()
utils/py/codex-turn.py:83:    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
utils/py/domain_oracles.py:467:        # 1. zero-state: read-only command keeps digest; a writer breaks it
utils/py/domain_oracles.py:468:        record("zero-state (+) read-only ls", check_zero_state(["ls", "-la"], work), True)
utils/py/muse-turn.py:226:    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
utils/py/marathon_drive.py:1247:        # GH-448: this resolution is the canonical write-side one — every read-only consumer (marathon-
utils/py/marathon_drive.py:2271:        "RELAY_TARGET_ROOT", "RELAY_TASK", "RELAY_WORKTREE_ISOLATION",
utils/py/aider-turn.py:170:    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
utils/py/releases_cycle.py:4:One read-only pass over releases.db that answers "where does the whole cycle stand":
utils/py/releases_cycle.py:15:Never writes to the database (read-only URI mode), so it is safe to run mid-merge.
utils/py/deepseek-turn.py:263:    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
utils/py/wave_reconcile.py:1875:        help="Run read-only pre-merge checks on closing active docs (frontmatter, lessons learned, test receipts) (GH-496)",
utils/py/relay_drive.py:79:    if get_env("RELAY_WORKTREE_ISOLATION") not in (None, "0", "1"):
utils/py/relay_drive.py:80:        die(f"RELAY_WORKTREE_ISOLATION must be 0 or 1 (got {get_env('RELAY_WORKTREE_ISOLATION')!r})")
utils/py/relay_drive.py:117:                    "worktree_isolation": get_env("RELAY_WORKTREE_ISOLATION", "1") != "0",
utils/py/relay_drive.py:292:    if "RELAY_WORKTREE_ISOLATION" not in os.environ:
utils/py/relay_drive.py:293:        os.environ["RELAY_WORKTREE_ISOLATION"] = "1"
utils/py/relay_drive.py:296:        if get_env("RELAY_WORKTREE_ISOLATION", "1") == "0":
utils/py/relay_drive.py:323:            eprint("  RELAY_WORKTREE_ISOLATION=1 runs the turn-taker in a worktree at HEAD, but its own")
utils/py/relay_drive.py:326:            eprint("  RELAY_WORKTREE_ISOLATION=0 if you want to rule out isolation entirely; neither is required.")
utils/py/relay_drive.py:332:            eprint("  first, or re-run with RELAY_WORKTREE_ISOLATION=0.")
utils/py/relay_drive.py:342:        if get_env("RELAY_WORKTREE_ISOLATION", "1") == "0":
utils/py/relay_drive.py:343:            eprint("relay-drive: WARNING — --artifact-file needs worktree isolation to seed the artifact; with RELAY_WORKTREE_ISOLATION=0 the reviewer will not see it.")
utils/py/relay_drive.py:488:        # via RELAY_WORKTREE_ISOLATION=1. The marathon driver already followed .git to the git COMMON
utils/py/relay_drive.py:788:            "isolated": get_env("RELAY_WORKTREE_ISOLATION", "1") == "1",
utils/py/relay_drive.py:849:                if get_env("RELAY_WORKTREE_ISOLATION", "1") != "0" and not turn_worktree:
utils/py/relay_drive.py:873:        if get_env("RELAY_WORKTREE_ISOLATION", "1") != "0" and not turn_worktree:
utils/py/jog_run.py:625:    read-only here — recovery never rewrites old receipts. Paths resolve relative-to-ledger
relay-automation/driver-lock-lib.sh:7:# read-only consumer of the lock (marathon-ls.sh, utils/hq/marathon-live.sh,
utils/py/claude-turn.py:171:    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
relay-automation/marathon-detail.sh:2:# marathon-detail.sh <repo> — preview for ONE repo path (read-only).
utils/py/harness_app.py:315:            ('muse', 'Muse Code', 'native_cli', 1, 1, 'muse exec --model {model} --reasoning-effort {effort} --workspace {workspace} --trust-workspace --prompt-file {task}', 'Evaluation only (GH-518)', 'Absolute MUSE_BIN (PATH not modified). Needs --workspace + --trust-workspace or the turn is read-only and silently writes nothing. Contributor tier carries a data-use clause: public repos only.'),
relay-automation/marathon-closeout.sh:11:# sequence without invoking git or gh, including read-only discovery commands.
utils/py/releases_app.py:270:    """Render the draft-card body; all GitHub state remains a read-only DB projection."""
utils/py/releases_app.py:5273:        result["error"] = ("unsupported ledger root for read-only diagnostics: "
utils/py/releases_app.py:5289:        result["error"] = "read-only open failed: %s" % exc
utils/py/releases_app.py:6182:    # read-only connection
utils/py/releases_app.py:6476:    sp_ws = wsub.add_parser("status", help="read-only work lifecycle and observation diagnostics")
utils/py/gate_env.py:78:    "RELAY_WORKTREE_ISOLATION": (
utils/py/gate_env.py:84:        "Seeds a read-only artifact into the worktree. A suite exercising --artifact-file would find "
relay-automation/aider-turn.sh:68:#   RELAY_WORKTREE_ISOLATION — 1 = run the turn in a THROWAWAY git worktree of ROOT@HEAD (airtight
relay-automation/aider-turn.sh:178:# structurally read-only in Aider even under --yes-always, so this gives full context with no writable
relay-automation/aider-turn.sh:274:if [[ "${RELAY_WORKTREE_ISOLATION:-0}" == "1" ]]; then
relay-automation/pi-turn.sh:31:# (RELAY_WORKTREE_ISOLATION=1) + rtl_enforce, not a Pi-native sandbox flag (there isn't one). Unlike
relay-automation/pi-turn.sh:63:#   RELAY_WORKTREE_ISOLATION — 1 = run the turn in a THROWAWAY git worktree of ROOT@HEAD (airtight
relay-automation/pi-turn.sh:175:if [[ "${RELAY_WORKTREE_ISOLATION:-0}" == "1" ]]; then
utils/py/rtl.py:898:    # every read-only consumer (marathon-ls.sh, marathon-live.sh, find-harness.sh) must resolve the
utils/py/review_xyz.py:394:        cflags = env.get("CODEX_FLAGS", "-s read-only").split()
utils/py/review_xyz.py:400:            "--dangerously-skip-permissions",
utils/py/pi-turn.py:121:    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
utils/py/site_build.py:9:  PAGES/models-harnesses.html <- harnesses.db (read-only; falls back to loading the
relay-automation/new-relay.sh:10:#   (default, reference) — the Setup points at .relay-artifacts/<basename>, the read-only path that
relay-automation/new-relay.sh:122:- Artifact under review: **.relay-artifacts/$art_base** — the read-only path that
utils/py/relay_drive.py:79:    if get_env("RELAY_WORKTREE_ISOLATION") not in (None, "0", "1"):
utils/py/relay_drive.py:80:        die(f"RELAY_WORKTREE_ISOLATION must be 0 or 1 (got {get_env('RELAY_WORKTREE_ISOLATION')!r})")
utils/py/relay_drive.py:117:                    "worktree_isolation": get_env("RELAY_WORKTREE_ISOLATION", "1") != "0",
utils/py/relay_drive.py:292:    if "RELAY_WORKTREE_ISOLATION" not in os.environ:
utils/py/relay_drive.py:293:        os.environ["RELAY_WORKTREE_ISOLATION"] = "1"
utils/py/relay_drive.py:296:        if get_env("RELAY_WORKTREE_ISOLATION", "1") == "0":
utils/py/relay_drive.py:323:            eprint("  RELAY_WORKTREE_ISOLATION=1 runs the turn-taker in a worktree at HEAD, but its own")
utils/py/relay_drive.py:326:            eprint("  RELAY_WORKTREE_ISOLATION=0 if you want to rule out isolation entirely; neither is required.")
utils/py/relay_drive.py:332:            eprint("  first, or re-run with RELAY_WORKTREE_ISOLATION=0.")
utils/py/relay_drive.py:342:        if get_env("RELAY_WORKTREE_ISOLATION", "1") == "0":
utils/py/relay_drive.py:343:            eprint("relay-drive: WARNING — --artifact-file needs worktree isolation to seed the artifact; with RELAY_WORKTREE_ISOLATION=0 the reviewer will not see it.")
utils/py/relay_drive.py:488:        # via RELAY_WORKTREE_ISOLATION=1. The marathon driver already followed .git to the git COMMON
utils/py/relay_drive.py:788:            "isolated": get_env("RELAY_WORKTREE_ISOLATION", "1") == "1",
utils/py/relay_drive.py:849:                if get_env("RELAY_WORKTREE_ISOLATION", "1") != "0" and not turn_worktree:
utils/py/relay_drive.py:873:        if get_env("RELAY_WORKTREE_ISOLATION", "1") != "0" and not turn_worktree:
relay-automation/consult.sh:40:# (Codex stays `-s read-only` on top of that; agy's writes, if any, are contained by the worktree.)
relay-automation/consult.sh:65:#   CODEX_FLAGS                codex sandbox flags (default: -s read-only)
relay-automation/consult.sh:76:# That is repo-isolation, NOT an OS sandbox — only Codex additionally gets `-s read-only`; a model
relay-automation/consult.sh:78:# "read-only", on purpose.
relay-automation/consult.sh:201:  local out="$1"; read -ra _f <<<"${CODEX_FLAGS:--s read-only}"
relay-automation/consult.sh:223:  _guarded "$out" "$AGY_BIN" --dangerously-skip-permissions --print-timeout "${secs}s" -p "$FULL_PROMPT"
utils/py/swarm_preflight.py:1126:            "RELAY_WORKTREE_ISOLATION": "1",
utils/py/swarm_preflight.py:1640:    invocation = f"""XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID={slug} RELAY_WORKTREE_ISOLATION=1 {drive_cmd} \\
relay-automation/marathon-drive.sh:957:# GH-162: peek at prior attempts BEFORE rendering (read-only; lane_attempt_gate in Step 3 still owns
relay-automation/agy-turn.sh:44:#   AGY_FLAGS      — optional extra flags appended to the agy invocation (advanced/override)
relay-automation/agy-turn.sh:54:#   RELAY_WORKTREE_ISOLATION — 1 = run the turn in a THROWAWAY git worktree of ROOT@HEAD (airtight
relay-automation/agy-turn.sh:59:#   --dangerously-skip-permissions — auto-approve tool calls (shell for tick, edit for the relay file)
relay-automation/agy-turn.sh:207:# just before the rtl watchdog would kill it; --model and AGY_FLAGS are optional pass-throughs.
relay-automation/agy-turn.sh:209:agy_args=(--dangerously-skip-permissions --print-timeout "${turn_timeout}s")
relay-automation/agy-turn.sh:211:read -ra _aflags <<<"${AGY_FLAGS:-}"
relay-automation/agy-turn.sh:219:# RELAY_WORKTREE_ISOLATION=1, run agy with CWD = a THROWAWAY git worktree of ROOT@HEAD, so any
relay-automation/agy-turn.sh:223:if [[ "${RELAY_WORKTREE_ISOLATION:-0}" == "1" ]]; then
relay-automation/claude-turn.sh:57:#   RELAY_WORKTREE_ISOLATION — 1 = run the builder turn in a THROWAWAY git worktree (ROADMAP 3.6 close):
relay-automation/claude-turn.sh:71:#   reviewers (codex-turn, gemini-turn)   → "Bash,Read"              (read-only; no write surface)
relay-automation/claude-turn.sh:213:# When RELAY_WORKTREE_ISOLATION=1, run the builder in a throwaway git worktree so any async/background
relay-automation/claude-turn.sh:217:if [[ "${RELAY_WORKTREE_ISOLATION:-0}" == "1" ]]; then
relay-automation/codex-turn.sh:37:#   CODEX_FLAGS     — autonomy flags for `codex exec` (default: -s workspace-write -c
relay-automation/codex-turn.sh:38:#                     approval_policy=never — GH-106: the old bare `-s workspace-write` default still
relay-automation/codex-turn.sh:42:#                     CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox' (removes codex's own
relay-automation/codex-turn.sh:53:#   RELAY_WORKTREE_ISOLATION — 1 = run the turn in a THROWAWAY git worktree of ROOT@HEAD (airtight
relay-automation/codex-turn.sh:133:# CODEX_FLAGS gives the turn enough autonomy to actually write on a fresh device (default sandbox is
relay-automation/codex-turn.sh:134:# read-only); operator-overridable for tighter/looser policies.
relay-automation/codex-turn.sh:137:# workspace-write sandbox restriction (still can't touch outside the workspace) — fully overridable.
relay-automation/codex-turn.sh:138:read -ra _cflags <<<"${CODEX_FLAGS:--s workspace-write -c approval_policy=never}"
relay-automation/codex-turn.sh:149:# When RELAY_WORKTREE_ISOLATION=1, run codex with CWD = a THROWAWAY git worktree of ROOT@HEAD, so any
relay-automation/codex-turn.sh:153:if [[ "${RELAY_WORKTREE_ISOLATION:-0}" == "1" ]]; then
relay-automation/codex-turn.sh:158:    # $TICK_REPO_ROOT/.tick is outside Codex's default workspace-write sandbox unless we add it.
relay-automation/codex-turn.sh:167:  # that Codex's CWD already equals ROOT so $TICK_REPO_ROOT/.tick sits inside its workspace-write
relay-automation/relay-drive.sh:212:  --artifact-file P   Seed an external read-only artifact (a cross-repo PR/diff or any file) into the
relay-automation/relay-drive.sh:309:# shims (codex/agy/claude-turn.sh) read RELAY_WORKTREE_ISOLATION; exporting it here makes every
relay-automation/relay-drive.sh:310:# DRIVEN turn contained by default. Opt out per run with RELAY_WORKTREE_ISOLATION=0. (Direct/attended
relay-automation/relay-drive.sh:312:: "${RELAY_WORKTREE_ISOLATION:=1}"; export RELAY_WORKTREE_ISOLATION
relay-automation/relay-drive.sh:327:  [[ "${RELAY_WORKTREE_ISOLATION:-1}" != 0 ]] || return 0
relay-automation/relay-drive.sh:345:    printf '  RELAY_WORKTREE_ISOLATION=1 runs the turn-taker in a worktree at HEAD, but its own\n' >&2
relay-automation/relay-drive.sh:348:    printf '  RELAY_WORKTREE_ISOLATION=0 if you want to rule out isolation entirely; neither is required.\n' >&2
relay-automation/relay-drive.sh:354:    printf '  first, or re-run with RELAY_WORKTREE_ISOLATION=0.\n' >&2
relay-automation/relay-drive.sh:402:# GH-31 / #15: a read-only artifact under review. Absolutize it (the shim runs with a different CWD)
relay-automation/relay-drive.sh:412:  [[ "$RELAY_WORKTREE_ISOLATION" != 0 ]] || \
relay-automation/relay-drive.sh:413:    printf 'relay-drive: WARNING — --artifact-file needs worktree isolation to seed the artifact; with RELAY_WORKTREE_ISOLATION=0 the reviewer will not see it.\n' >&2
relay-automation/relay-turn-lib.sh:368:  # REVIEWER-turn scoping: a reviewer is near read-only — it only APPENDS findings to the relay file
relay-automation/relay-turn-lib.sh:458:  # read-only into the worktree by rtl_worktree_begin at .relay-artifacts/<basename> — NOT added to
relay-automation/relay-turn-lib.sh:460:  # changes its signature and fails the turn (strict read-only). Empty/unset → no artifact (default).
relay-automation/relay-turn-lib.sh:691:# OPT-IN: callers gate on RELAY_WORKTREE_ISOLATION=1. Default OFF → behaviour is unchanged.
relay-automation/relay-turn-lib.sh:703:#     READ-ONLY artifact at .relay-artifacts/<basename> — the read-only seed set distinct from the writable
relay-automation/relay-turn-lib.sh:800:  # GH-31 / #15: seed the read-only artifact under review so an ISOLATED reviewer can READ it (it is
relay-automation/relay-turn-lib.sh:803:  # edit changes the signature and trips off-lane (strict read-only). NOT in RTL_ALLOW ⇒ never copied back.
relay-automation/relay-turn-lib.sh:904:    # GH-31 / #15: the read-only artifact seed. Exempt ONLY while unchanged from the seed; a reviewer
relay-automation/relay-turn-lib.sh:905:    # edit changes the .relay-artifacts dir signature → strict-fail as off-lane (read-only enforced,
relay-automation/relay-turn-lib.sh:1044:  # GH-31 / #15: point the reviewer at the seeded read-only artifact (worktree-relative; it is NOT a
relay-automation/relay-turn-lib.sh:1186:# rtl_has_uncited_claim's read-only predicate (used by consult.sh's A4 stamp) — so the two stay in
relay-automation/relay-turn-lib.sh:1244:# GH-178 A4 follow-up (code review on PR #184): read-only predicate reused by consult.sh's advisor
relay-automation/marathon-ls.sh:2:# marathon-ls.sh — cross-repo marathon monitor engine (read-only).
test/gh91-relay-scratch.sh:163:[ "$erc" -eq 0 ] && pass "rtl_enforce: the turn PASSES with ignored scratch present (exit 0, not 6)" \
test/gh91-relay-scratch.sh:164:  || fail "rtl_enforce: turn failed (exit $erc) over ignored scratch"
test/gh91-relay-scratch.sh:165:[ ! -d "$E/.relay-scratch" ] && pass "rtl_enforce: ignored scratch is STILL discarded (unconditional sweep)" \
test/gh91-relay-scratch.sh:166:  || fail "rtl_enforce: ignored scratch survived the turn"
relay-automation/relay-turn-lib.sh:199:# stay gitignored (see .gitignore's "relay-system/logs/" entry) — rtl_check already removes any file
relay-automation/relay-turn-lib.sh:201:# agent edit"), so an UN-ignored path here would be silently deleted at the end of every single turn,
relay-automation/relay-turn-lib.sh:547:rtl_is_containment_ignored() {  # <path> — is <path> an exempted tool-cache side-effect write?
relay-automation/relay-turn-lib.sh:916:    rtl_is_containment_ignored "$path" && continue   # GH-107: opt-in tool-cache exemption
relay-automation/relay-turn-lib.sh:1049:  # is exactly what the daybreak builder ignored while doing precisely what it was asked to.
relay-automation/relay-turn-lib.sh:1353:  # (1) allowlist enforcement on tracked-tree changes (.tick is gitignored, so token ops don't show).
relay-automation/relay-turn-lib.sh:1357:  # ignored-file safety belongs to the agent sandbox, tracked as future.
relay-automation/relay-turn-lib.sh:1383:  # it — porcelain omits ignored paths, so the per-path rtl_check discard above never fires and
relay-automation/relay-turn-lib.sh:1464:    # GH-304 (secondary): an empty commit set is AMBIGUOUS when the relay file is gitignored (this repo
relay-automation/relay-turn-lib.sh:1465:    # gitignores parts of relay-system/). `git add -A` can't stage a gitignored path, so a turn that DID
relay-automation/relay-turn-lib.sh:1466:    # append findings to a gitignored relay file lands here with the SAME empty _commit_paths as a
relay-automation/relay-turn-lib.sh:1469:    # the relay file (RTL_ALLOW[0], repo-root-relative) is gitignored, say so plainly and point at the
relay-automation/relay-turn-lib.sh:1474:      printf '%s-turn: %s turn made no git commit — relay file %s is gitignored, so any content it appended is NOT git-tracked (this is expected, NOT a stall — read the file to confirm what the turn wrote)\n' "$RTL_TOOL" "$agent" "$_relay_rel"
relay-automation/relay-turn-lib.sh:1475:      rtl_log_always "rtl_enforce: COMMIT none (relay file gitignored, on-disk change untracked) agent=$agent rel=$_relay_rel"
relay-automation/relay-turn-lib.sh:1589:  # gitignored persistent log (the GH-161 default, under relay-system/logs/) must NEVER be swept here —
relay-automation/relay-turn-lib.sh:1591:  # ignored paths, so it only flags the genuine stray case rtl_check already handles mid-loop (an
relay-automation/relay-turn-lib.sh:1592:  # un-ignored log path that reappeared after our late writes) — never a tracked file, never an
relay-automation/relay-turn-lib.sh:1593:  # intentionally-ignored one.
relay-automation/relay-turn-lib.sh:1615:# per-device, gitignored): only drift events NEWER than the watermark and NOT authored by <agent> are
     1	#!/usr/bin/env bash
     2	# test/gh91-relay-scratch.sh — GH-91: a sanctioned scratch dir for builder verification output.
     3	#
     4	# The 0.7.2 daybreak wave-1 re-fire: the builder ran its probes (collect.sh → JSON), saved the
     5	# output next to the thing being probed to feed triage.py — exactly what the brief's pass
     6	# condition required — and containment reverted all four JSON files at exit 6. The turn's
     7	# deliverable was complete and green. Every other category of incidental write already had an
     8	# exemption (.tick, .relay-artifacts, the transcript log, GH-107 tool caches); builder scratch
     9	# had nothing, and "$TMPDIR" was convention carried only in prose the builder demonstrably did
    10	# not weight.
    11	#
    12	# The fix (issue option 1): `.relay-scratch/` — exempted in rtl_check and rtl_worktree_end
    13	# exactly as the other intrinsic categories, pre-created by rtl_worktree_begin, named in
    14	# rtl_turn_prompt so the affordance is visible at the point of use. Never copied back; on the
    15	# non-worktree path it is discarded (it lives in RTL_ROOT there and must not linger or ride
    16	# into a commit). This suite drives the lib functions directly — no agy/codex binary, no
    17	# timing dependence.
    18	set -uo pipefail
    19	
    20	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    21	LIB="$HERE/relay-automation/relay-turn-lib.sh"
    22	
    23	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh91-relay-scratch.XXXXXX")"
    24	[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "FATAL: mktemp -d failed" >&2; exit 1; }
    25	. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"
    26	fixture_guard_init "$WORK"
    27	trap 'rm -rf "$WORK"' EXIT
    28	
    29	PASS=0; FAIL=0
    30	pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
    31	fail() { echo "  FAIL: $*"; FAIL=$((FAIL+1)); }
    32	
    33	# A throwaway repo standing in for RTL_ROOT with one committed allowlist lane file.
    34	R="$WORK/repo"
    35	mkdir -p "$R"
    36	require_fixture "$R" "fixture repo"
    37	git -C "$R" init -q
    38	git -C "$R" config user.email t@example.com
    39	git -C "$R" config user.name t
    40	printf 'lane v1\n' >"$R/lane.md"
    41	git -C "$R" add -A
    42	git -C "$R" commit -qm init
    43	
    44	# shellcheck source=/dev/null
    45	source "$LIB"
    46	RTL_ROOT="$R"
    47	RTL_TOOL="test"
    48	RTL_LOG=""
    49	RTL_LOG_REL=""
    50	RTL_ARTIFACT=""
    51	
    52	# ── (1) rtl_check: scratch under ROOT is exempted AND discarded, and the turn does not fail ─────
    53	RTL_ALLOW=("lane.md")
    54	printf 'lane v2\n' >"$R/lane.md"                          # the legitimate lane edit
    55	mkdir -p "$R/.relay-scratch"
    56	printf '{"lens":2}\n' >"$R/.relay-scratch/out2.json"      # the probe output that killed the real turn
    57	printf '{"lens":3}\n' >"$R/.relay-scratch/out3.json"
    58	RTL_VIOLATION=0
    59	rtl_check ".relay-scratch/out2.json"
    60	[ "$RTL_VIOLATION" -eq 0 ] && pass "rtl_check: a scratch write is NOT a violation" \
    61	  || fail "rtl_check: scratch write flagged as violation"
    62	[ ! -d "$R/.relay-scratch" ] && pass "rtl_check: the scratch dir is DISCARDED from ROOT (not committed, not lingering)" \
    63	  || fail "rtl_check: scratch dir still present in ROOT after the check"
    64	cmp -s <(printf 'lane v2\n') "$R/lane.md" && pass "rtl_check: the legitimate lane edit is untouched" \
    65	  || fail "rtl_check: lane edit damaged by scratch handling"
    66	
    67	# The collapsed-dir form (git shows ".relay-scratch/" when the dir is wholly untracked) — same branch.
    68	mkdir -p "$R/.relay-scratch"; printf 'x\n' >"$R/.relay-scratch/probe.json"
    69	RTL_VIOLATION=0
    70	rtl_check ".relay-scratch/"
    71	[ "$RTL_VIOLATION" -eq 0 ] && [ ! -d "$R/.relay-scratch" ] \
    72	  && pass "rtl_check: the collapsed '.relay-scratch/' status form is exempted and discarded too" \
    73	  || fail "rtl_check: collapsed-dir form not handled"
    74	
    75	# ── (2) containment still BITES: scratch is a room, not an amnesty ───────────────────────────────
    76	printf 'stray\n' >"$R/stray.txt"
    77	RTL_VIOLATION=0
    78	rtl_check "stray.txt"
    79	[ "$RTL_VIOLATION" -eq 1 ] && pass "CONTROL: a stray file OUTSIDE .relay-scratch still violates (exit-6 path intact)" \
    80	  || fail "CONTROL: stray write not flagged — the exemption is an amnesty, not a room"
    81	[ ! -f "$R/stray.txt" ] && pass "CONTROL: the stray file is reverted as before" \
    82	  || fail "CONTROL: stray file survived"
    83	# A lookalike prefix must NOT ride the exemption.
    84	mkdir -p "$R/.relay-scratch2"; printf 'x\n' >"$R/.relay-scratch2/out.json"
    85	RTL_VIOLATION=0
    86	rtl_check ".relay-scratch2/out.json"
    87	[ "$RTL_VIOLATION" -eq 1 ] && pass "CONTROL: '.relay-scratch2' (lookalike prefix) is NOT exempt" \
    88	  || fail "CONTROL: lookalike prefix .relay-scratch2 slipped the exemption"
    89	
    90	# ── (3) worktree isolation: begin pre-creates the dir, end exempts it and never copies it back ──
    91	git -C "$R" checkout -q -- lane.md 2>/dev/null || true
    92	RTL_ALLOW=("lane.md")
    93	wt="$(rtl_worktree_begin)"
    94	[ -d "$wt/.relay-scratch" ] && pass "rtl_worktree_begin: the scratch dir EXISTS in the worktree (affordance, not prose)" \
    95	  || fail "rtl_worktree_begin: scratch dir not pre-created"
    96	# the builder's turn: edit the lane file AND leave probe output in the sanctioned place
    97	printf 'lane v2\n' >"$wt/lane.md"
    98	printf '{"lens":2}\n' >"$wt/.relay-scratch/out2.json"
    99	rtl_worktree_end "$wt"
   100	[ "$RTL_WT_OFFLANE" -eq 0 ] && pass "rtl_worktree_end: probe output in .relay-scratch is NOT off-lane" \
   101	  || fail "rtl_worktree_end: scratch marked off-lane (the GH-91 fire reproduced)"
   102	cmp -s <(printf 'lane v2\n') "$R/lane.md" && pass "rtl_worktree_end: the lane edit still copies back" \
   103	  || fail "rtl_worktree_end: lane edit did not copy back"
   104	[ ! -e "$R/.relay-scratch" ] && pass "rtl_worktree_end: scratch is NEVER copied back to ROOT" \
   105	  || fail "rtl_worktree_end: scratch leaked into ROOT"
   106	
   107	# ── (4) worktree containment still bites beside the new room ────────────────────────────────────
   108	wt2="$(rtl_worktree_begin)"
   109	printf 'lane v3\n' >"$wt2/lane.md"
   110	printf 'stray\n' >"$wt2/stray.txt"
   111	rtl_worktree_end "$wt2"
   112	[ "$RTL_WT_OFFLANE" -eq 1 ] && pass "CONTROL: a stray write in the worktree still goes off-lane" \
   113	  || fail "CONTROL: worktree stray not flagged"
   114	cmp -s <(printf 'lane v2\n') "$R/lane.md" && pass "CONTROL: off-lane turns copy NOTHING back (lane edit withheld)" \
   115	  || fail "CONTROL: off-lane turn still copied the lane edit back"
   116	
   117	# ── (5) the prompt names the affordance at the point of use ─────────────────────────────────────
   118	RTL_ROOT="$R"
   119	out="$(rtl_turn_prompt builder "$R/lane.md" TASK lane.md)"
   120	grep -q '.relay-scratch' <<<"$(printf '%s' "$out")" \
   121	  && pass "rtl_turn_prompt: the prompt TELLS the builder where scratch goes" \
   122	  || fail "rtl_turn_prompt: scratch affordance not named"
   123	grep -q 'never copied back' <<<"$(printf '%s' "$out")" \
   124	  && pass "rtl_turn_prompt: and says what happens to it (never copied back)" \
   125	  || fail "rtl_turn_prompt: scratch disposition not stated"
   126	# PR #93 review, finding 1: the format string must carry a conversion for EVERY argument —
   127	# bash printf RECYCLES the format when args outnumber conversions, printing the whole ~13-
   128	# sentence template a second time with $scratch_note garbled into the agent slot. The old
   129	# substring-only assertions passed right through that; these pin cardinality and position.
   130	[ "$(printf '%s' "$out" | grep -c 'You are agent')" -eq 1 ] \
   131	  && pass "rtl_turn_prompt: the template renders EXACTLY once (no printf recycling)" \
   132	  || fail "rtl_turn_prompt: template rendered $(printf '%s' "$out" | grep -c 'You are agent') times — arg/conversion mismatch"
   133	[ "$(printf '%s' "$out" | grep -c '.relay-scratch')" -eq 1 ] \
   134	  && pass "rtl_turn_prompt: the scratch note appears exactly once" \
   135	  || fail "rtl_turn_prompt: scratch note appears $(printf '%s' "$out" | grep -c '.relay-scratch') times"
   136	grep -q 'gate after your turn. Verification output' <<<"$(printf '%s' "$out")" \
   137	  && pass "rtl_turn_prompt: the note lands in its own slot at the end of the template" \
   138	  || fail "rtl_turn_prompt: scratch note is not in the intended position"
   139	
   140	# ── (6) INTEGRATION (PR #93 review, finding 2): through rtl_enforce, ignore rule in place ───────
   141	# The reviewer's exact reproduction: a repo whose .gitignore hides .relay-scratch/ never shows
   142	# the dir in porcelain, so rtl_check's per-path discard cannot fire. rtl_enforce must still
   143	# discard it (the unconditional sweep) and the turn must not fail.
   144	E="$WORK/enforce-repo"
   145	mkdir -p "$E"
   146	require_fixture "$E" "enforce repo"
   147	git -C "$E" init -q
   148	git -C "$E" config user.email t@example.com
   149	git -C "$E" config user.name t
   150	printf 'lane v1\n' >"$E/lane.md"
   151	printf '.relay-scratch/\n' >"$E/.gitignore"
   152	git -C "$E" add -A
   153	git -C "$E" commit -qm init
   154	RTL_ROOT="$E"; RTL_ALLOW=("lane.md"); RTL_LOG=""; RTL_LOG_REL=""; RTL_ARTIFACT=""
   155	RTL_WT_USED=0; RTL_WAS_REVIEWER_TURN=0; unset RTL_WT
   156	rtl_before
   157	printf 'lane v2\n' >"$E/lane.md"                       # the legitimate edit
   158	mkdir -p "$E/.relay-scratch"; printf 'probe\n' >"$E/.relay-scratch/out.json"
   159	[ -z "$(git -C "$E" status --porcelain -- .relay-scratch)" ] \
   160	  && pass "INTEGRATION precondition: the ignore rule really hides scratch from porcelain" \
   161	  || fail "INTEGRATION precondition: scratch visible despite ignore rule"
   162	rtl_enforce TASK builder "" test; erc=$?
   163	[ "$erc" -eq 0 ] && pass "rtl_enforce: the turn PASSES with ignored scratch present (exit 0, not 6)" \
   164	  || fail "rtl_enforce: turn failed (exit $erc) over ignored scratch"
   165	[ ! -d "$E/.relay-scratch" ] && pass "rtl_enforce: ignored scratch is STILL discarded (unconditional sweep)" \
   166	  || fail "rtl_enforce: ignored scratch survived the turn"
   167	# .tick/ is the harness's own coordination state (exempt by design) — everything ELSE must be
   168	# clean: the lane edit committed file-scoped, scratch swept, nothing else lingering.
   169	[ -z "$(git -C "$E" status --porcelain | grep -v '^?? \.tick/')" ] \
   170	  && pass "rtl_enforce: the lane edit was committed file-scoped; nothing lingers but .tick/ (exempt coordination state)" \
   171	  || fail "rtl_enforce: tree dirty after enforce: $(git -C "$E" status --porcelain | head -3)"
   172	
   173	echo "  gh91-relay-scratch: $PASS pass, $FAIL fail"
   174	[ "$FAIL" -eq 0 ]
     1	---
     2	gh_issue: 91
     3	source: https://github.com/HiQS-Labs/XYZ-forge/issues/91
     4	title: "fix(relay): a build turn has nowhere to write verification output — containment kills a complete, green turn"
     5	status: Active (2-WORKING — built 2026-08-20)
     6	created: 2026-08-20
     7	updated: 2026-08-20
     8	owner: noelsaw1
     9	doc_type: bugfix
    10	effort: 1
    11	complexity: 2
    12	risk: 3
    13	goal: >
    14	  Give every build turn a sanctioned place inside the tree for verification output —
    15	  .relay-scratch/ — exempted like the other intrinsic write categories, pre-created by
    16	  worktree isolation, named in the turn prompt, never copied back, discarded rather than
    17	  committed on the non-worktree path. Containment otherwise unchanged: stray writes and
    18	  lookalike prefixes still fail the turn.
    19	related:
    20	  - https://github.com/HiQS-Labs/XYZ-forge/issues/90
    21	  - https://github.com/HiQS-Labs/XYZ-forge/issues/107
    22	---
    23	
    24	# GH-91: the sanctioned scratch directory
    25	
    26	## Status
    27	
    28	| What was just completed | What's next |
    29	|---|---|
    30	| **BUILT 2026-08-20 (linked worktree `XYZ-forge-gh91`, branch `fix/gh91-relay-scratch`)** — issue option 1 implemented across all four surfaces: `rtl_worktree_begin` pre-creates `.relay-scratch/` in the isolated worktree (the affordance physically exists, not prose); `rtl_worktree_end` exempts it intrinsically (no signature check — it is *meant* to be written, unlike the read-only `.relay-artifacts/` seed) and never copies it back; `rtl_check` on the non-worktree path exempts AND discards it (`rm -rf` — it lives in ROOT there and must neither linger nor ride into a commit); `rtl_turn_prompt` names it at the point of use with its disposition. `.gitignore` carries `.relay-scratch/` as defense in depth (the exemption is intrinsic in code and does not depend on it, per the `.tick` lesson). New suite `test/gh91-relay-scratch.sh` **15/0** with controls: stray writes still violate, lookalike prefix `.relay-scratch2` is NOT exempt, off-lane worktree turns still copy nothing back. Containment-pinning neighbors re-run green (worktree-isolation 33/0, shim-worktree 32/0, relay-artifact-file 13/0, rtl-orphan-backup 8/0, gh410 11/0, path-overlap, relay-xyz-skill-guard, untracked-file-warn, seeding-visibility, relay-target-root). | Full gate from a NORMAL clone (GH-45 refuses it from this worktree — by design), then PR into `development`. Watch the next daybreak re-fire: the builder should now put probe output in `.relay-scratch/` because the prompt says so at the point of use. If a lane still writes scratch elsewhere, that is a prompt-weighting question for GH-77's briefs, not a missing facility. |
    31	
    32	## The defect (abridged from the issue)
    33	
    34	The 0.7.2 daybreak wave-1 re-fire: the builder verified its work exactly as the brief required
    35	(`collect.sh` → JSON → `triage.py --lenses --dry-run`, all green), saved the probe output next to
    36	the thing being probed — and containment reverted all four JSON files at exit 6, failing a
    37	complete, passing turn. Every other category of incidental write had an exemption
    38	(`.tick/`, `.relay-artifacts/`, the transcript log, GH-107 tool caches); builder scratch had
    39	none, and `$TMPDIR` was convention carried only in prose the builder demonstrably did not weight.
    40	A rule a competent builder breaks while doing exactly what it was asked to do is a missing
    41	affordance, not a discipline problem.
    42	
    43	## The fix (issue option 1 — recommended)
    44	
    45	`.relay-scratch/`, treated as an intrinsic write category:
    46	
    47	| Surface | Change |
    48	|---|---|
    49	| `rtl_worktree_begin` | `mkdir -p "$wt/.relay-scratch"` — the affordance physically exists before the turn starts |
    50	| `rtl_worktree_end` | intrinsic `case` exemption beside `.tick` (NO signature check — scratch is meant to be written); copyback iterates `RTL_ALLOW` only, so it is structurally never copied back |
    51	| `rtl_check` (non-worktree) | exempt AND discard: `rm -rf "${RTL_ROOT:?}/.relay-scratch"` — the transcript-log drop is the precedent; `${RTL_ROOT:?}` guards the empty-prefix `rm -rf` (GH-567) |
    52	| `rtl_turn_prompt` | one sentence naming the room and its disposition: exempt, never copied back, safe to leave; scratch elsewhere still fails the turn |
    53	| `.gitignore` | ~~`.relay-scratch/`~~ — **REVERTED in review**: the entry hid the dir from porcelain, so `rtl_enforce`'s per-path `rtl_check` discard never fired and scratch lingered in ROOT forever (the reviewer reproduced it end-to-end). The real guarantee is the unconditional sweep in `rtl_enforce`, independent of git visibility |
    54	
    55	## Validation
    56	
    57	| What | Result |
    58	|---|---|
    59	| `test/gh91-relay-scratch.sh` (new, registered in TESTS same commit) | **22/0** — lib-function level, no builder binary: scratch not a violation + discarded + lane edit untouched (both the file and collapsed-dir status forms); CONTROLS: stray write still exit-6s and is reverted, `.relay-scratch2` lookalike not exempt, worktree stray still off-lane with copyback withheld; begin pre-creates the dir; end exempts without copying back; prompt names the room and its disposition. **PR #93 review round:** prompt template renders EXACTLY once (printf arg/conversion cardinality — bash recycles the format and a 14th arg without a 14th `%s` doubled the whole template garbled; the old substring greps passed through that, so the pins are cardinality + position now), and an INTEGRATION case through `rtl_enforce` with `.relay-scratch/` gitignored: turn passes (exit 0), ignored scratch still discarded, lane edit committed file-scoped |
    60	| Containment-pinning neighbors | worktree-isolation 33/0 · shim-worktree 32/0 · relay-artifact-file 13/0 · rtl-orphan-backup 8/0 · gh410 11/0 · path-overlap 1/0 · relay-xyz-skill-guard 11/0 · relay-untracked-file-warn 9/0 · relay-file-seeding-visibility 3/0 · relay-target-root 12/0 |
    61	| shellcheck `-S error` on the lib | clean |
    62	| Full `./validate.sh` | **GREEN 229/229** (2026-08-20, from the parent clone's NORMAL checkout at the exact final commit — the worktree itself refuses the gate, GH-45 working as designed). The gate also caught that editing a packaged file obligates a `make-pkg.sh` regeneration: `relay-pkg-freshness.sh` went red until the vendored `relay-pkg.tar.gz` was rebuilt and committed with the lib change. One process note recorded honestly: the first gate pass ran with the regenerated tarball as an uncommitted working-tree file in the gate clone; the final 229/229 is on the committed state, after regenerating inside the branch and re-gating (make-pkg.sh is not byte-deterministic — freshness compares packaged content, not tar bytes) |
    63	
    64	## Design notes
    65	
    66	- **Why exempt-and-discard in `rtl_check` but leave-in inside worktrees**: under isolation the
    67	  dir dies with the worktree, so leaving it is free; on the non-worktree path it lives in
    68	  `RTL_ROOT`, where lingering untracked scratch would ride into someone's `git add -A` — the
    69	  transcript-log drop is the standing precedent for "harness-owned, dropped, not flagged".
    70	- **Why no signature check** (unlike `.relay-artifacts/`): the artifact seed is read-only under
    71	  review, so any edit is a violation; scratch exists precisely to be written by the turn.
    72	- **Why the prompt line matters as much as the exemption**: the phase brief already said "use
    73	  `$TMPDIR`" and the builder wrote to CWD anyway. The affordance is now visible at the point of
    74	  use, in the same sentence as the rule it replaces.
    75	
    76	## Lessons Learned (For Future Agents)
    77	
    78	- When a containment rule kills a turn whose deliverable is green, the question is not "how do
    79	  we make the builder behave" but "what legitimate action has no sanctioned home". Inventory the
    80	  write categories; each one missing a room becomes an exit 6 waiting to fire.
    81	- An exemption is a room, not an amnesty: the suite pins that stray writes and lookalike
    82	  prefixes (`.relay-scratch2`) still fail — otherwise the fix would just relocate the hole.

exec
/bin/zsh -lc "nl -ba utils/py/relay_drive.py | sed -n '284,347p'
nl -ba utils/py/agy-turn.py | sed -n '396,438p'
nl -ba relay-automation/relay-turn-lib.sh | sed -n '535,570p;680,710p'
nl -ba AGENTS.md | sed -n '1,30p' 2>/dev/null || true
rg -n \"Run the suite in a SEPARATE FULL CLONE|Never run.*test/\\*\\.sh|linked worktree\" AGENTS.md | sed -n '1,40p'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-93733-mu26k550
 succeeded in 0ms:
   284	        except RuntimeError:
   285	            tick_repo_root = root_dir
   286	        os.environ["TICK_REPO_ROOT"] = tick_repo_root
   287	
   288	    # check lane attempt
   289	    if not args.dry_run and not args.review_once:
   290	        lane_attempt_gate(tick_repo_root, args.relay_task, args.force)
   291	
   292	    if "RELAY_WORKTREE_ISOLATION" not in os.environ:
   293	        os.environ["RELAY_WORKTREE_ISOLATION"] = "1"
   294	
   295	    def warn_if_relay_file_untracked():
   296	        if get_env("RELAY_WORKTREE_ISOLATION", "1") == "0":
   297	            return
   298	        rdir = os.path.dirname(os.path.abspath(relay_file))
   299	        if not os.path.isdir(rdir):
   300	            return
   301	
   302	        try:
   303	            prefix = subprocess.check_output(["git", "-C", rdir, "rev-parse", "--show-prefix"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
   304	        except Exception:
   305	            return
   306	        rel = prefix + os.path.basename(relay_file)
   307	        try:
   308	            subprocess.run(["git", "-C", rdir, "cat-file", "-e", f"HEAD:{rel}"], stderr=subprocess.DEVNULL, check=True)
   309	            return
   310	        except subprocess.CalledProcessError:
   311	            pass
   312	
   313	        try:
   314	            relay_toplevel = subprocess.check_output(["git", "-C", rdir, "rev-parse", "--show-toplevel"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
   315	            effective_root = get_env("RELAY_TARGET_ROOT", root_dir)
   316	            effective_toplevel = subprocess.check_output(["git", "-C", effective_root, "rev-parse", "--show-toplevel"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
   317	        except Exception:
   318	            relay_toplevel = ""
   319	            effective_toplevel = ""
   320	
   321	        if relay_toplevel and relay_toplevel == effective_toplevel:
   322	            eprint(f"relay-drive: NOTE — relay file is not committed at HEAD: {rel}")
   323	            eprint("  RELAY_WORKTREE_ISOLATION=1 runs the turn-taker in a worktree at HEAD, but its own")
   324	            eprint("  worktree-seeding step copies this file's current content in regardless — this is")
   325	            eprint("  usually fine. Commit it for a clean paper trail, or re-run with")
   326	            eprint("  RELAY_WORKTREE_ISOLATION=0 if you want to rule out isolation entirely; neither is required.")
   327	        else:
   328	            eprint(f"relay-drive: WARNING — relay file is not committed at HEAD: {rel}")
   329	            eprint("  It lives in a DIFFERENT repo than the turn-taker's root (archive-routed?), so the")
   330	            eprint("  usual worktree-seeding fallback does NOT cover it — it may be genuinely INVISIBLE to")
   331	            eprint("  the reviewer (it will find nothing and do no work). Remedy: commit the relay file")
   332	            eprint("  first, or re-run with RELAY_WORKTREE_ISOLATION=0.")
   333	
   334	    warn_if_relay_file_untracked()
   335	
   336	    if args.artifact_file:
   337	        if not os.path.isfile(args.artifact_file):
   338	            die(f"artifact file not found: {args.artifact_file}")
   339	        if not args.artifact_file.startswith("/"):
   340	            args.artifact_file = os.path.abspath(args.artifact_file)
   341	        os.environ["RELAY_ARTIFACT_FILE"] = args.artifact_file
   342	        if get_env("RELAY_WORKTREE_ISOLATION", "1") == "0":
   343	            eprint("relay-drive: WARNING — --artifact-file needs worktree isolation to seed the artifact; with RELAY_WORKTREE_ISOLATION=0 the reviewer will not see it.")
   344	
   345	    def file_status():
   346	        try:
   347	            with open(relay_file, 'r') as f:
   396	    # GH-161 parity fix: codex-turn.py already uses rtl_default_log (persistent, gitignored
   397	    # relay-system/logs/<day>/... — survives past the turn); this port was missed, the same gap
   398	    # found and fixed in aider-turn.py/aider-turn.sh.
   399	    agy_log = os.environ.get("AGY_LOG") or rtl_default_log(root, "agy-turn", t)
   400	    
   401	        # GH-320: this default MUST match the Bash twin's `${RELAY_TURN_TIMEOUT_S:-N}` and the
   402	    # ceiling its header documents. It read 300 while the twin said 900, and since Python is the
   403	    # executing lane every turn was silently capped at a fraction of the documented budget —
   404	    # observed live as an exit-7 kill on a review turn that had 900s on paper.
   405	    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 900))
   406	    agy_args = ["--dangerously-skip-permissions", "--print-timeout", f"{turn_timeout}s"]
   407	    
   408	    if os.environ.get("AGY_MODEL"):
   409	        agy_args += ["--model", os.environ.get("AGY_MODEL")]
   410	        
   411	    aflags = os.environ.get("AGY_FLAGS", "").split()
   412	    if aflags:
   413	        agy_args += aflags
   414	
   415	    rtl.before()
   416	    
   417	    wt = ""
   418	    run_cwd = root
   419	    run_env = dict(os.environ)
   420	    # GH-308 port: the Bash twin does `: "${TICK_REPO_ROOT:=$ROOT}"; export TICK_REPO_ROOT` at the top,
   421	    # so the agy child (which runs `tick` mid-turn) ALWAYS inherits TICK_REPO_ROOT=root. Python only set
   422	    # it inside the worktree-isolation branch, so on the default non-worktree lane a cross-repo run
   423	    # (AGY_TURN_ROOT != CWD) left agy's mid-turn `tick` resolving against its CWD instead of the target.
   424	    run_env["TICK_REPO_ROOT"] = tick_repo_root
   425	
   426	    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
   427	        wt = rtl.worktree_begin()
   428	        if wt:
   429	            run_env["TICK_REPO_ROOT"] = tick_repo_root
   430	            run_cwd = wt
   431	            print(f"agy-turn: worktree isolation ON ({wt})", file=sys.stderr)
   432	        else:
   433	            print("agy-turn: worktree isolation requested but `git worktree add` failed — failing turn", file=sys.stderr)
   434	            sys.exit(5)
   435	
   436	    cmd = [agy_bin] + agy_args + ["-p", prompt]
   437	    bounded_rc = 0
   438	    
   535	  return 0
   536	}
   537	
   538	# GH-107: opt-in tool-cache exemption for rtl_worktree_end's off-lane loop. A builder's own tooling
   539	# can write an untracked cache dir as a side effect of an otherwise fully-allowlisted turn (observed
   540	# live: .codebase-memory/ from a codebase-memory MCP server discarded a 442-line, 67/67-green build);
   541	# without an exemption that single stray dir fails the whole turn (sibling of #54 — same mechanism,
   542	# different trigger). Built-in list = tool caches this harness has already had to gitignore for the
   543	# same reason; CONTAINMENT_IGNORE (comma-separated glob patterns, empty by default) extends it with
   544	# no code change. Deliberately additive and root-anchored: tracked-file detection and every
   545	# non-matching path keep today's off-lane behavior byte-for-byte; a nested cache (e.g.
   546	# sub/.codebase-memory/) is NOT exempted by the built-ins — opt in explicitly via CONTAINMENT_IGNORE.
   547	rtl_is_containment_ignored() {  # <path> — is <path> an exempted tool-cache side-effect write?
   548	  local x="$1" pat
   549	  local pats=('.codebase-memory' '.aider*' 'node_modules/.cache')
   550	  if [[ -n "${CONTAINMENT_IGNORE:-}" ]]; then
   551	    # read -ra (not an unquoted for-loop) so a glob pattern like `.mytool*` is never pathname-expanded
   552	    # against the CWD; bash-3.2/BSD-portable like the rest of this lib.
   553	    local extra=()
   554	    IFS=',' read -ra extra <<<"$CONTAINMENT_IGNORE"
   555	    pats+=("${extra[@]}")
   556	  fi
   557	  for pat in "${pats[@]}"; do
   558	    pat="${pat%/}"
   559	    [[ -n "$pat" ]] || continue
   560	    # Match the path itself, git's collapsed all-untracked form `dir/`, and anything under it.
   561	    # $pat is intentionally unquoted: case-glob matching is the contract.
   562	    # shellcheck disable=SC2254
   563	    case "$x" in $pat|$pat/|$pat/*) return 0 ;; esac
   564	  done
   565	  return 1
   566	}
   567	
   568	rtl_run_bounded() {  # <timeout_secs> <cmd...>
   569	  # Run <cmd...> under a wall-clock ceiling without coreutils `timeout` (absent on stock macOS).
   570	  # Mirrors the consult.sh _guarded() pattern: sleep-then-kill watchdog, no external deps.
   680	    return 2
   681	  fi
   682	  printf 'finished'
   683	  return 1
   684	}
   685	
   686	# --- Worktree isolation (ROADMAP Part A Phase 3.6 — the airtight async/side-effect close) ----------
   687	# Before touching anything below: read WORKTREE-SAFETY.md (repo root) — it documents the
   688	# git-worktree footguns and the safe recovery path for a corrupted RTL_ROOT/.git (GH-177). This is
   689	# the one place in the harness that runs `git worktree add`/cleanup at runtime; every turn shim
   690	# (aider/agy/codex/claude-turn.sh) and consult.sh reach worktree isolation through this file.
   691	# OPT-IN: callers gate on RELAY_WORKTREE_ISOLATION=1. Default OFF → behaviour is unchanged.
   692	# Run the agent turn in a THROWAWAY git worktree of RTL_ROOT@HEAD, so any async/background write
   693	# lands in a tree we delete — RTL_ROOT is never the agent's target. This closes the gap left by the
   694	# point-in-time `rtl_enforce` + the (macOS-absent) setsid process-group reap: ROOT safety no longer
   695	# depends on killing the process group, because the agent can't reach ROOT in the first place.
   696	# Coordination state (.tick) stays SHARED — the caller must run the agent with TICK_REPO_ROOT=RTL_ROOT.
   697	#
   698	# SEED LIMITATIONS (relay review 2026-06-23 F4/F5 — known constraints, documented; structural fix deferred):
   699	#   - Cross-repo / uncommitted artifact: the worktree is a checkout of RTL_ROOT@HEAD and seeds only
   700	#     allowlisted paths UNDER RTL_ROOT (below). An artifact in ANOTHER repo, or a brand-new uncommitted
   701	#     one, is neither at HEAD nor on the writable allowlist, so it would be invisible to an isolated turn.
   702	#     FIX (GH-31 / closes #15): set RELAY_ARTIFACT_FILE (relay-drive `--artifact-file`) to seed it as a
   703	#     READ-ONLY artifact at .relay-artifacts/<basename> — the read-only seed set distinct from the writable
   704	#     allowlist. The reviewer may READ it; an edit changes its signature and fails the turn (strict-fail);
   705	#     it is never copied back to RTL_ROOT (no leak). See rtl_init (RTL_ARTIFACT) + the seed/exempt logic
   706	#     in rtl_worktree_begin/end. (Embedding inline still works for callers who prefer it.)
   707	_rtl_sig() {  # <path> — content signature of a file/dir, or "ABSENT". Used to detect what the turn
   708	  # actually changed IN THE WORKTREE, so rtl_worktree_end copies back ONLY worktree-modified paths and
   709	  # never clobbers a ROOT-direct edit with a stale seed (GH-22). git is already required by this lib.
   710	  local p="$1"
     1	# AGENTS.md
     2	
     3	## Danger: commands agents must not run
     4	
     5	- Never run `git reset --hard`, `git checkout -- <path>`, or a tree-wide `git stash` in a checkout
     6	  whose state matters; they overwrite tracked work or hide shared worktree-family state.
     7	- Never run `rm -rf`, `find ... -delete`, or equivalent recursive cleanup through an empty,
     8	  unresolved, relative, root, home, workspace, or otherwise unproven target path.
     9	- Never remove or move a linked worktree with `rm -rf` or `mv`, and never hand-delete
    10	  `.git/worktrees/*`; use `git worktree remove` / `move` / `prune` / `repair`.
    11	- Never run sandboxed `git switch --track` or `git branch -D` directly; wrap the complete command
    12	  with `utils/git-sandbox-guard.sh --repo <root> -- <git command>`.
    13	- Never delete or move a full-clone folder until its working tree, stashes, local refs, and registered
    14	  worktrees prove that it contains no unique or depended-on state.
    15	- Never run `validate.sh` or `test/*.sh` from a linked worktree or a full clone whose state matters;
    16	  run mutation-heavy gates only in a separate disposable full clone.
    17	
    18	Read [`WORKTREE-SAFETY.md`](WORKTREE-SAFETY.md) for the rationale, recovery paths, and safe patterns.
    19	
    20	> **Safety and warranty:** XYZ Forge is provided **“AS IS,” without warranty**, under the applicable
    21	> license. Coding models may choose commands through their own runtimes and safety controls, outside
    22	> the intended harness workflow. XYZ Forge cannot guarantee model behavior or data integrity; maintain
    23	> tested, independent backups and follow industry-standard backup and recovery practices.
    24	
    25	Read `ROUTER.md` first for startup order and canonical files.
    26	
    27	Read `GUIDING-PRINCIPLES.md` for the product north stars — its "The North Star" section (durable,
    28	reversible, DRY; extend what exists rather than forking a parallel system) is canonical and governs
    29	everything below.
    30	
9:- Never remove or move a linked worktree with `rm -rf` or `mv`, and never hand-delete
15:- Never run `validate.sh` or `test/*.sh` from a linked worktree or a full clone whose state matters;
175:    `.git/hooks/`, which covers **every branch and linked worktree** of that clone, including branches
311:  on the driver's own lock dir inside a linked worktree, and untracked artifacts are invisible to a
319:- **Run the suite in a SEPARATE FULL CLONE, never in a clone whose state you care about — and a
320:  linked worktree is NOT a way around it (GH-564).** `validate.sh` and `test/*.sh` can write to the
328:    linked worktrees cut off the primary clone, chosen specifically to isolate the risk. **Linked
332:    driver-lock matrix documents from the other side (GH-42/GH-354/GH-448) — a linked worktree

exec
/bin/zsh -lc "nl -ba GUIDING-PRINCIPLES.md | sed -n '18,75p'
nl -ba AGENTS.md | sed -n '305,345p'
nl -ba relay-automation/relay-turn-lib.sh | sed -n '1204,1221p;1382,1398p'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-93733-mu26k550
 succeeded in 0ms:
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
    36	XYZ Forge is a local-first operations system for humans directing agents across their repositories:
    37	capture → rate → plan → preflight → execute → gate → land → record. Its `tick` kernel coordinates
    38	local claims through an event log and exclusive locks; its relay and Marathon tooling drive bounded
    39	build and review work. Containment controls reduce accidental writes but do not guarantee safety
    40	outside their enforced boundaries; linked worktrees share Git state. The product prioritizes
    41	coordination, recoverability and verifiable outcomes. The operator remains the decision authority.
    42	
    43	XYZ is not enterprise application lifecycle management or an agent marketplace. It currently
    44	assumes specified work rather than providing a structured spec/PRD-generation pipeline of its own;
    45	that capability gap is not a permanent prohibition on future product work. PDDA’s governance-layer
    46	anti-scope does not prohibit XYZ’s coordination and execution features.
    47	
    48	## The quality bar
    49	
    50	Every agent turn is a signal. A turn is high-quality only when it is all four:
    51	
    52	- **Attested** — carries its receipts: source, evidence, confidence. Never a bare verdict. A relay review names which claim is wrong and why; a build turn names the seam it touched.
    53	- **Relevant** — ranked, not dumped. Volume is not value. One real bug beats five nits and a phantom.
    54	- **Fresh** — current, not stale. A turn that reads a stale `STATE.md` or misses an epoch fence is wrong by construction.
    55	- **Structured** — one shape, clean for the operator to read and for downstream agents to feed on.
    56	
    57	Fail a pillar, and the turn, feature, or relay review isn't done.
    58	
    59	## How it's built
    60	
    61	1. **Coordination is local-transport only.** `.tick/events/` is the shared bus; claims resolve from there, not from a remote. No per-event push/fetch; no remote dependency at runtime. A coordination primitive that reaches out is a coordination primitive that can fail or leak.
    62	
    63	2. **One canonical event log for tick coordination.** `.tick/events/` records coordination events; `.tick/STATE.md` is a derived view. Coordination verbs read and fold the events and append changes through the event API. Other subsystems retain their own documented sources of truth, including the RELEASES roadmap ledger. Do not create competing copies of canonical state.
    64	
    65	3. **Containment is non-negotiable.** A headless turn must not: self-commit mid-turn, orphan a peer's concurrent commit, or write outside its allowlist. The allowlist, worktree isolation, and commit-bypass guard exist because a driven agent will do all three if unconstrained — not hypothetically, but as documented live incidents (GH-13, GH-14, GH-17). New relay paths must clear the containment bar before they ship.
    66	
    67	4. **Skill-first; never improvise the harness.** The `relay-xyz` skill owns the locator, sandbox rules, exit codes, and the safety boundary. A session that improvises those from `ls relay-automation/` silently skips the skill's safety layer. In sessions that install and invoke the `PreToolUse` hook, `relay-automation/hooks/relay-xyz-guard.sh` checks supported driver invocations for the skill’s setup evidence; this is not a guarantee that every runtime invokes that hook. Add capabilities to the skill; do not work around it.
    68	
    69	5. **Adversarially proven before commercially viable.** The harness exists to run against real codebases. Features in the adversarial-hardening track (epoch fencing, chaos suite, cross-repo E2E) must be verified to survive deliberate abuse — stale writers, zombie claims, macOS case-sensitivity, concurrent peer commits — not just the happy path. A feature that clears the happy path and skips chaos is half-done.
    70	
    71	6. **Build durable, not band-aid.** Durable means it removes the root cause and the next planned change builds on it — not a patch torn out when the obvious next feature lands. A band-aid is wasted work unless a demo strictly needs one, and a demo band-aid is tagged for removal so it isn't silently inherited.
    72	
    73	7. **Least code that clears the bar.** The `tick` coordination kernel uses Node's standard library. The repository also ships `package.json` and `package-lock.json` for Acorn-based source analysis. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.
    74	
    75	8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.
   305	  tree (this repo has been wiped twice — see
   306	  `PROJECT/3-COMPLETED/GH-177-MKTEMP-TRAP-REPO-WIPE.md`). Know what it does NOT protect: worktrees
   307	  share `.git` objects/refs, so destructive *git* operations (`update-ref`, `branch -D`, resets,
   308	  force-push) still hit the real repo — a worktree-isolated agent once reset ROOT HEAD via
   309	  `rtl_enforce`'s commit-bypass guard. Harness-driven codex/agy lanes are covered by
   310	  `rtl_worktree_begin` instead and don't need the flag. Known frictions: `--require-clean` self-trips
   311	  on the driver's own lock dir inside a linked worktree, and untracked artifacts are invisible to a
   312	  worktree checkout — commit review inputs first. Read-only subagents (Explore, audits) don't need
   313	  isolation. Related guards: never execute `validate.sh`/`test/*.sh` under a sandboxed Bash call
   314	  (enforced by `relay-automation/hooks/gh177-sandbox-test-guard.sh` — re-run it un-sandboxed; do NOT
   315	  push it to CI to be exercised, see the CI rail below), and `test/mktemp-trap-guard.sh` statically
   316	  outlaws the wipe idiom repo-wide. **The "what it does NOT protect" list above is narrower than
   317	  reality — see the next rail (GH-564): a worktree isolates the working tree only, and everything
   318	  under `.git` is shared, which is why running the suite in one contaminated the parent clone twice.**
   319	- **Run the suite in a SEPARATE FULL CLONE, never in a clone whose state you care about — and a
   320	  linked worktree is NOT a way around it (GH-564).** `validate.sh` and `test/*.sh` can write to the
   321	  git config, remotes, and refs of the repository they are invoked from. On 2026-08-15 the primary
   322	  clone was contaminated **twice in one morning**: `core.bare=true`, `remote.origin.url` repointed at
   323	  a fixture bare repo, a fixture `[user]` identity appended, and `refs/heads/development` reset onto
   324	  ~35 fixture commits. It also **defeated the push gate while corrupting it** — pushes failed with
   325	  `'/var/folders/…/bare.XXXXXX' does not appear to be a git repository` because the suite repointed
   326	  `origin` mid-hook.
   327	  - **The worktree precaution was taken and it FAILED.** Both bursts came from `./validate.sh` run in
   328	    linked worktrees cut off the primary clone, chosen specifically to isolate the risk. **Linked
   329	    worktrees share `.git/config` with the parent clone**, so an escape landing in a worktree's CWD
   330	    writes the parent's config. Reproduced deterministically: from a worktree CWD, `r=""; git -C "$r"
   331	    remote set-url origin "$b"` rewrote the *parent* clone's origin. Same structural fact the
   332	    driver-lock matrix documents from the other side (GH-42/GH-354/GH-448) — a linked worktree
   333	    resolves to the parent's `git-common-dir`, which is why it grants no second lane either.
   334	  - **State the boundary precisely, because the previous rail's version was too narrow.** The rail
   335	    above says worktree isolation does not protect against destructive *git operations*. That is
   336	    true and insufficient: a worktree isolates the **working tree only**. Everything reached through
   337	    `.git` — config, remotes, refs, objects, hooks — is shared with the parent clone, whether it is
   338	    touched deliberately or by an escaped fixture. Only a **separate full clone** isolates any of it.
   339	  - **Why it escapes at all:** `git -C ""` is documented to leave the working directory unchanged and
   340	    `cd ""` is a bash no-op, and these suites run without `set -e` — so one unguarded
   341	    `r="$(mktemp -d …)"` silently redirects every "fixture" operation onto the caller's clone. It
   342	    fires under **parallel** load (the failure mode of `mktemp`), which is why a serial re-run of the
   343	    same suite reproduces nothing and must not be read as an all-clear. GH-177 family.
   344	  - **Until #564's suite-wide invariant gate lands**, treat any clone you ran the suite in as
   345	    suspect: check `git config --get core.bare`, `git remote -v`, `git config --local --get user.email`,
  1204	# The [Pass] tag check MUST stay an inline `/\[Pass\]/` literal in each awk SCRIPT below (not a -v
  1205	# value) — inline /regex/ delimiters are compiled directly, bypassing the -v string-unescape step.
  1206	RTL_CLAIM_WORD_RE='(^|[^A-Za-z])([Vv]erified|[Cc]onfirmed|LGTM|[Ll]ooks [Gg]ood|[Cc]hecks [Oo]ut|[Aa]ll [Gg]ood|[Ww]orks [Aa]s [Ee]xpected|[Nn]o issues( found)?)([^A-Za-z]|$)'
  1207	RTL_CITATION_RE='"[^"]+"|`[^`]+`|[A-Za-z0-9_./-]+:[0-9]+'
  1208	
  1209	# GH-173 B3: mechanical uncited-"verified" check. new-relay.sh's own Reviewer template ("▶ TAKE YOUR
  1210	# TURN" block) now ASKS for a citation on any [Pass]/"verified" finding, but a prompt instruction is
  1211	# model compliance, not a guarantee — Jedi Wright's beta report hit exactly that gap (a "verified"
  1212	# claim with no quote). This does NOT verify a citation is ACCURATE (out of scope, no real
  1213	# citation-verification engine); it only catches the ABSENCE of one, mechanically, and downgrades the
  1214	# claim in place so the caveat is structural rather than trusting the model followed the instruction.
  1215	# A "citation" is a quoted span ("..."/`...`) or a file:line reference (name:NNN) within the next
  1216	# RTL_CITATION_WINDOW (default 3) lines, INCLUDING the claim's own line (inline citations count).
  1217	rtl_check_uncited_findings() {  # <relay_file_path> — rewrites the file in place
  1218	  local f="$1" win="${RTL_CITATION_WINDOW:-3}" tmp
  1219	  [[ -n "$f" && -f "$f" ]] || return 0
  1220	  tmp="${f}.rtlcite.$$"
  1221	  awk -v win="$win" -v word_re="$RTL_CLAIM_WORD_RE" -v cite_re="$RTL_CITATION_RE" '
  1382	  # GH-91 (PR #93 review): scratch must not survive the turn EVEN WHEN the host repo gitignores
  1383	  # it — porcelain omits ignored paths, so the per-path rtl_check discard above never fires and
  1384	  # the dir lingered in ROOT forever. Sweep unconditionally, independent of git visibility.
  1385	  [[ -d "${RTL_ROOT:?}/.relay-scratch" ]] && rm -rf "${RTL_ROOT:?}/.relay-scratch"
  1386	  rtl_trace "rtl_enforce: RTL_VIOLATION=$RTL_VIOLATION"
  1387	  ((RTL_VIOLATION == 0)) || { printf '%s-turn: off-lane edits reverted; failing the turn\n' "$RTL_TOOL" >&2; rtl_log_always "rtl_enforce: VIOLATION off-lane edits reverted; failing the turn"; exit 6; }
  1388	  # GH-173 B3: downgrade any uncited [Pass]/verified Reviewer finding BEFORE staging, so the fix lands
  1389	  # in the SAME commit as the turn instead of needing a second one. Reviewer-only (Producer findings
  1390	  # aren't graded by this template); RTL_WAS_REVIEWER_TURN was captured in rtl_init, before NEXT flipped.
  1391	  if [[ "${RTL_WAS_REVIEWER_TURN:-0}" == "1" && -n "${RELAY_FILE:-}" ]]; then
  1392	    rtl_check_uncited_findings "$RELAY_FILE"
  1393	    rtl_trace "rtl_enforce: checked $RELAY_FILE for uncited [Pass]/verified findings"
  1394	  fi
  1395	  # GH-410 / GH-21 / AGENTS.md §12: structural relay-block validation before staging.
  1396	  # The Reviewer turn must append a structurally valid review block (STATUS not In Progress,
  1397	  # ## Log present, VERDICT, and Basis).
  1398	  # If validation fails, exit 8 (relay block structural validation failed) so the harness

codex
VOTE A: YES-WITH-CHANGE  
Reason (≤5 bullets, cite file:line you actually read):

- [Pass] `.relay-scratch/` is already pre-created, exempt, and never copied back, so it is suitable for captured probe output (`relay-automation/relay-turn-lib.sh:820-826`, `relay-automation/relay-turn-lib.sh:895-898`).
- [Blocker] “existing tests and fixtures” contradicts the repository’s explicit ban on running `test/*.sh` from linked worktrees: they can mutate shared Git configuration and refs (`AGENTS.md:15-16`, `AGENTS.md:319-338`).
- [Should] Enforcement sees `git status --porcelain`, which omits ignored side effects; the code admits ignored-file safety is deferred, while only `.relay-scratch/` receives an unconditional sweep (`relay-automation/relay-turn-lib.sh:1353-1357`, `relay-automation/relay-turn-lib.sh:1382-1385`).
- [Should] “Read-only execution” is behavioral, not enforced: Codex relay turns default to `workspace-write`, while Agy disables its permission checks (`utils/py/codex-turn.py:14-17`, `utils/py/agy-turn.py:406-413`). Worktree isolation defaults on, but only isolates the working tree (`utils/py/relay_drive.py:292-293`).
- [Pass] Out-of-relay review is not equivalent: it catches bad approvals only after the bounded relay has spent its rounds and emitted an unusable result.

Change (if YES-WITH-CHANGE): Permit only narrow, non-mutating probes/queries against the seeded artifact; explicitly forbid `validate.sh`, `test/*.sh`, and executable fixtures inside the relay worktree. Require probe execution/output under `.relay-scratch/` with `TMPDIR` redirected there and `PYTHONDONTWRITEBYTECODE=1`; tests require a separate disposable full clone.

VOTE B: YES-WITH-CHANGE  
Reason (≤5 bullets, cite file:line):

- [Pass] Requiring a counterexample aligns with the repository’s evidence-first quality bar: review claims need receipts, not bare verdicts (`GUIDING-PRINCIPLES.md:48-57`).
- [Blocker] “Design change, not a fix to an observed defect” is too subjective. The motivating global-completeness request could readily be described as a defect fix, so the proposed rule would not reliably catch this case.
- [Blocker] A prose-only patch cannot truthfully promise automatic downgrade. The existing GH-173 implementation explicitly says prompt compliance is not a guarantee and therefore performs an actual rewrite during enforcement (`relay-automation/relay-turn-lib.sh:1209-1217`, `relay-automation/relay-turn-lib.sh:1388-1393`).
- [Should] Trigger on scope, not intent: a request that changes behavior for inputs beyond the cited reproduction or Definition of Done is a generalization and needs a falsifier.
- [Pass] Supplying the falsifier in the original finding need not consume another round; it can prevent the Producer from spending one implementing an unsupported generalization. The default cap is four (`relay-automation/new-relay.sh:24`, `relay-automation/new-relay.sh:95-97`).

Change (if YES-WITH-CHANGE): Require every behavior-generalizing finding to include `Observed input:`, `Affected scope:`, and `Falsifier:`. Without them, instruct the Producer to treat it as `[Should — unproven generalization]`; do not call the downgrade mechanical unless enforcement code is added.

One risk the other advisor will probably miss: Relay Codex uses `-s workspace-write`, not `-s read-only`; the latter is the consult default, so A cannot rely on a read-only Codex sandbox (`utils/py/codex-turn.py:14-17`).
tokens used
120,573
VOTE A: YES-WITH-CHANGE  
Reason (≤5 bullets, cite file:line you actually read):

- [Pass] `.relay-scratch/` is already pre-created, exempt, and never copied back, so it is suitable for captured probe output (`relay-automation/relay-turn-lib.sh:820-826`, `relay-automation/relay-turn-lib.sh:895-898`).
- [Blocker] “existing tests and fixtures” contradicts the repository’s explicit ban on running `test/*.sh` from linked worktrees: they can mutate shared Git configuration and refs (`AGENTS.md:15-16`, `AGENTS.md:319-338`).
- [Should] Enforcement sees `git status --porcelain`, which omits ignored side effects; the code admits ignored-file safety is deferred, while only `.relay-scratch/` receives an unconditional sweep (`relay-automation/relay-turn-lib.sh:1353-1357`, `relay-automation/relay-turn-lib.sh:1382-1385`).
- [Should] “Read-only execution” is behavioral, not enforced: Codex relay turns default to `workspace-write`, while Agy disables its permission checks (`utils/py/codex-turn.py:14-17`, `utils/py/agy-turn.py:406-413`). Worktree isolation defaults on, but only isolates the working tree (`utils/py/relay_drive.py:292-293`).
- [Pass] Out-of-relay review is not equivalent: it catches bad approvals only after the bounded relay has spent its rounds and emitted an unusable result.

Change (if YES-WITH-CHANGE): Permit only narrow, non-mutating probes/queries against the seeded artifact; explicitly forbid `validate.sh`, `test/*.sh`, and executable fixtures inside the relay worktree. Require probe execution/output under `.relay-scratch/` with `TMPDIR` redirected there and `PYTHONDONTWRITEBYTECODE=1`; tests require a separate disposable full clone.

VOTE B: YES-WITH-CHANGE  
Reason (≤5 bullets, cite file:line):

- [Pass] Requiring a counterexample aligns with the repository’s evidence-first quality bar: review claims need receipts, not bare verdicts (`GUIDING-PRINCIPLES.md:48-57`).
- [Blocker] “Design change, not a fix to an observed defect” is too subjective. The motivating global-completeness request could readily be described as a defect fix, so the proposed rule would not reliably catch this case.
- [Blocker] A prose-only patch cannot truthfully promise automatic downgrade. The existing GH-173 implementation explicitly says prompt compliance is not a guarantee and therefore performs an actual rewrite during enforcement (`relay-automation/relay-turn-lib.sh:1209-1217`, `relay-automation/relay-turn-lib.sh:1388-1393`).
- [Should] Trigger on scope, not intent: a request that changes behavior for inputs beyond the cited reproduction or Definition of Done is a generalization and needs a falsifier.
- [Pass] Supplying the falsifier in the original finding need not consume another round; it can prevent the Producer from spending one implementing an unsupported generalization. The default cap is four (`relay-automation/new-relay.sh:24`, `relay-automation/new-relay.sh:95-97`).

Change (if YES-WITH-CHANGE): Require every behavior-generalizing finding to include `Observed input:`, `Affected scope:`, and `Falsifier:`. Without them, instruct the Producer to treat it as `[Should — unproven generalization]`; do not call the downgrade mechanical unless enforcement code is added.

One risk the other advisor will probably miss: Relay Codex uses `-s workspace-write`, not `-s read-only`; the latter is the consult default, so A cannot rely on a read-only Codex sandbox (`utils/py/codex-turn.py:14-17`).
