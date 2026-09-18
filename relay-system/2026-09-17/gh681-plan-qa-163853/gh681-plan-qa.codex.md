**SINGLE-MODEL — NOT RECONCILED** (only codex answered; 1 of 2 requested advisor(s) failed — this is one model's read, not a cross-model consult. Do not treat any claim below as cross-verified.)

**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-6-astra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
OpenAI Codex v0.153.4
--------
workdir: /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-17340-oelbhd71
model: gpt-6-astra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 01a0b1bc-cafb-71e2-b601-f779849637bd
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# QA consult: falsify this implementation plan for HiQS-Labs/XYZ-forge#681

You are one of two independent advisors (the other is a different model). You are in a throwaway worktree of XYZ-forge at `development`. **Read the cited files yourself** before answering; do not trust the plan's quotations. Advisory only; write nothing.

Your job is not to approve. It is to find where this plan is wrong, under-scoped, or unfalsifiable. The plan already survived one consult (Codex + agy) whose findings it incorporates; look for what *that* round missed.

Answer the five questions in §8 of the plan, then give a verdict. Strict format at the end.

---

# GH-681 — Reviewer may probe read-only; generalizations carry a falsifier

Refined implementation plan after the first consult (Codex + agy, adjudicated 2026-09-17, recorded on #681). Every `file:line` below was read on `development` at the time of writing.

## 1. Ground truth (recon)

| Fact | Where | Why it matters |
|---|---|---|
| The reviewer role note is a single bash string; every runtime uses it. `utils/py/rtl.py:792 turn_prompt` shells out to `rtl_turn_prompt`, so Python (authoritative) and `XYZ_PYTHON=0` bash lanes share one source. | `relay-automation/relay-turn-lib.sh:1040-1043` | Exactly one edit point for A. No twin to keep in sync. |
| The current note forbids running anything: "do NOT edit, create, or **run** any artifact or source file". It ends with "When approving, hand the token off with done and set STATUS: Approved." | `:1042` | The second sentence is what driver attestation keys on (GH-505/509/510). `test/gh505-relay-attest.sh` case G asserts the reviewer prompt contains "set STATUS: Approved" — the first draft of A dropped it and would have gone red there. |
| `.relay-scratch/` is pre-created per worktree, named in the prompt, exempt from containment, never copied back. | `:820-826`, scratch_note `:1050` | Home for probe output. |
| `rtl_scratch_relocate` refuses dot-directories (`.*`), so `.pytest_cache/` (not gitignored — `.gitignore:36` has only `__pycache__/`) is off-lane → `RTL_WT_OFFLANE=1` (`:924`) → exit 6. | `:1128` | Test suites in the worktree discard the turn. Scope A to probes. |
| Ignored-file residue is invisible to enforcement by design: "ignored-file safety belongs to the agent sandbox, tracked as future." | `:1357` | `__pycache__` from a probe is harmless in a throwaway worktree, but note it. |
| Relay Codex runs `-s workspace-write -c approval_policy=never`; agy runs with permissions skipped. | `codex-turn.sh:138`, `utils/py/codex-turn.py:17` | "Read-only execution" is behavioural. The post-turn porcelain diff is the backstop. |
| `AGENTS.md:15-16`: never run `validate.sh` or `test/*.sh` from a linked worktree; mutation-heavy gates only in a disposable full clone. | `AGENTS.md:15` | A must not contradict a written rule. |
| GH-173 B3's downgrade of uncited `[Pass]` is a real awk rewrite in `rtl_check_uncited_findings`, run from `rtl_enforce` on reviewer turns. | `:1217-1242`, `:1391-1393` | B must not claim a mechanical downgrade it doesn't have. |
| The `TAKE YOUR TURN` reviewer bullet lives in the scaffold; `--print` emits it. | `relay-automation/new-relay.sh:79-92`, `:35` | Edit point for B; testable via `--print`. |
| `skills/relay-xyz/SKILL.md:604-609` is a "Reviewers … commensurate complexity" standard; `relay-xyz` is the skill deployed on this device (`~/git-pulse-sync/Deployed Skills/relay-xyz`). | | Second codification point; the deployable unit. |
| `/express` refuses this change mechanically: `SHARED_RUNTIME = relay-turn-lib.sh` (`shared-runtime`), and any edited `.sh` under `relay-automation/` (`no-new-bash`, GH-551). | `utils/py/express.py:41-61`, `:454-470` | Lane is the fresh-clone PR, per the skill's own fallback. |

## 2. Diagnosis (what this fixes)

In `relay-system/2026-09-17/gh673-final-qa.md` the Reviewer, forbidden to execute, generalized a real late-error observation (`connectors.py:92-93`) into "or a later invalid identity", the Producer implemented it, and the same Reviewer `[Pass]`ed it next round. One historical `NULL`-URL ledger row then blanks every issue. Two harness properties allowed it: the reviewer cannot measure (`:1042`), and a reviewer-authored generalization carries no falsifier and is self-certified (`new-relay.sh:79-92` guards observations, not requests).

## 3. Change set (minimal)

All prose unless marked. No shell or Python logic changes.

**S1 — A, the role note** (`relay-turn-lib.sh:1042`, replace the string):
> You are the REVIEWER this turn: do NOT edit or create any artifact or source file. You MAY run narrow, non-mutating probes and queries against the seeded artifact to measure a claim (for Python use `python3 -B`; put all output and any temp files under `.relay-scratch/`, e.g. `mkdir -p .relay-scratch/tmp && TMPDIR=.relay-scratch/tmp`). Do NOT run `validate.sh`, `test/*.sh`, or executable fixtures here — those belong in a separate disposable full clone. Never modify a tracked file, including databases. Any change to the tree outside the relay file is reverted and fails your turn. When approving, hand the token off with done and set STATUS: Approved.

Kept verbatim: the opening phrase (`test/gh397` asserts it) and the closing sentence (`test/gh505` case G asserts it).

**S2 — B, the scaffold** (`new-relay.sh` reviewer bullet, after the GH-173 sentence; plus the Producer bullet):
> A finding whose requested behaviour applies to inputs beyond its cited reproduction or the Definition of Done is a **generalization** and MUST carry three lines: `Observed input:` (what you actually saw), `Affected scope:` (the inputs the change would govern), `Falsifier:` (the fixture or data that would show the generalization is unnecessary or wrong). A `[Blocker]` must cite an observed failure — a failing run, probe output, or a concrete counterexample in existing data or fixtures. The Producer may disposition a generalization lacking these as `Declined — unproven generalization`.

Producer bullet: `(Implemented / Modified / Declined + why)` → `(Implemented / Modified / Declined + why — including "Declined — unproven generalization")`.

**S3 — second codification** (`skills/relay-xyz/SKILL.md`, in the Reviewers standard at `:604-609`): two numbered items restating S1's allowance/limits and S2's generalization rule, each pointing at the harness text as canonical.

**S4 — README row** (`relay-automation/README.md`, the `relay-turn-lib.sh` row): one sentence — reviewers may run non-mutating probes into `.relay-scratch/`; containment is unchanged and ignored-file residue remains a known gap.

**S5 — regression suite** `test/gh681-reviewer-probe-rules.sh`, registered in `validate.sh` `TESTS=(…)`. Mirrors `test/gh304-vendored-relay-path.sh` (sources the lib, `rtl_init` on a temp relay, calls `rtl_turn_prompt`). Asserts:
1. reviewer prompt contains "MAY run narrow, non-mutating probes", "`.relay-scratch/`", "Do NOT run `validate.sh`, `test/*.sh`", "hand the token off with done and set STATUS: Approved";
2. reviewer prompt does **not** contain "or run any artifact";
3. producer prompt contains none of the reviewer-only sentences;
4. `new-relay.sh --print` output contains `Observed input:`, `Affected scope:`, `Falsifier:`, `Declined — unproven generalization`;
5. `rtl_scratch_relocate` still returns 1 for `.pytest_cache` (backstop unchanged);
6. `skills/relay-xyz/SKILL.md` contains both rule phrases (drift guard, like `gh660`).
Red controls (run once, receipts in `TESTS-RESULTS/<date>+GH-681/`): revert S1 → cases 1-2 red; drop the closing sentence → case 1 red (the consult Blocker, now mechanical); revert S2 → case 4 red.

**S6 — paperwork**: `PROJECT/2-WORKING/GH-681-REVIEWER-PROBES.md` (Status / Acceptance / Merge evidence / Lessons Learned), `CHANGELOG.md` entry.

**Deferred to a follow-up issue (not this change):** harness-set `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR` for reviewer turns. It would touch the five Python shims that launch CLIs (`utils/py/{codex,agy,claude,pi,aider}-turn.py`) — a logic change across Tier-A twins, not commensurate here. S1's prose guidance covers the common case.

## 4. Blast radius and reversibility

- S1 changes the prompt every headless *reviewer* turn receives, in every lane that sources the lib (Codex, agy, Claude, Pi, Aider) and both runtimes. Producer turns unchanged. `rtl_enforce`, `rtl_worktree_end`, the allowlist scoping (`:368-380`) and the GH-173 rewrite are untouched — the containment backstop is exactly what it was.
- S2 changes only newly scaffolded relay files; existing relays keep their embedded block.
- S3/S4 are documentation; S3 propagates to devices on the next `relay-xyz` re-vendor.
- Reversibility: **Easy** — revert the commit; no state, schema, or generated artifacts. AGENTS classes containment-surface edits as at least Costly, which is why it goes through review rather than express.

## 5. Lane

1. Fresh task clone off `origin/development` (SOP §4), branch `fix/gh681-reviewer-probe-rules`.
2. Run `python3 utils/py/express.py check --issue 681 --suite test/gh681-reviewer-probe-rules.sh --dry-run` **first** and keep its refusal output as the receipt that express is not the lane (expected: `shared-runtime` on `relay-turn-lib.sh`, `no-new-bash` on `new-relay.sh`).
3. Implement S1-S6; run the suite; run `bash test/gh308-frozen-twin-guard.sh --check --staged` (expect clean — the lib is not a twin, and no new `.sh` is added under `relay-automation/`; `test/` is exempt).
4. Full `validate.sh` in a separate disposable clone, per `AGENTS.md:15`.
5. Push the branch; open a PR with `Closes #681`, the consult links, and the express-refusal receipt. Merge is the operator's call.

## 6. Acceptance (verifiable)

- `bash test/gh681-reviewer-probe-rules.sh` → all cases pass; red-control receipts show the three intended failures.
- `test/gh397` and `test/gh505` still pass unchanged (the kept phrases are their assertions).
- `validate.sh` green in a disposable clone; GH-308 guard clean.
- Post-merge smoke (integration, not a gate): one driven relay in which a reviewer turn runs a probe into `.relay-scratch/` and the turn is attested (shim exit 0, no containment revert). Record it on #681.

## 7. Deploy (after merge)

`python3 "$HOME/git-pulse-sync/Deployed Skills/intake.py" update relay-xyz --source "<XYZ-forge>/skills/relay-xyz"` — preview, then apply; commit the reviewed portable paths in the Pulse checkout; sync targets. Per the skills-army-hq SOP the source must be *landed* first; a deploy from an unmerged branch is refused by the process, not just discouraged.

## 8. Questions for the QA consult

1. Is scoping A to "narrow, non-mutating probes" (excluding test suites in the worktree) the right cut, or does it leave the reviewer unable to measure the cases that matter? Give one concrete measurement a reviewer would need that this wording forbids.
2. S2's trigger is *scope* ("inputs beyond the cited reproduction or DoD"). Is that determinable by a headless reviewer from the finding alone? Propose a sharper test if not.
3. Is deferring the harness-set env (`PYTHONDONTWRITEBYTECODE`, `TMPDIR`) safe, or does prose guidance leave a turn-discarding residue path open in the probes-only scope?
4. Does the test suite (S5) actually falsify the change, or only its wording? Name a mutant that passes S5 but breaks the intent.
5. Anything in S1 that contradicts `skills/relay/SKILL.md:249` (the generic protocol's "Do not edit the artifact") or `AGENTS.md`?

---

## Answer format (strict; put this block LAST)

```
Q1: <answer, ≤4 lines, cite file:line you read>
Q2: <…>
Q3: <…>
Q4: <name one mutant that passes S5 but breaks intent, or state none exists and why>
Q5: <…>
NEW DEFECTS (things the plan does not know about; each with file:line and a fix): 
- …
VERDICT: PROCEED | PROCEED-WITH-CHANGES | STOP
Changes required before proceeding (if any):
- …
One thing the other advisor will probably get wrong:
```

codex
I’ll check the prompt, containment, and test paths for gaps the first consult missed. I’m using the SWE and debug-mantra skills to assess the plan’s claims and acceptance checks.

exec
/bin/zsh -lc 'pwd; cat ROUTER.md; cat /Users/noelsaw/.codex/skills/swe/SKILL.md; cat /Users/noelsaw/.codex/skills/debug-mantra/SKILL.md' in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-17340-oelbhd71
 succeeded in 0ms:
/private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-17340-oelbhd71
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
---
name: swe
description: Apply software-engineering standards when authoring or reviewing project plans, build/spec/PRD documents, architecture RFCs, or agent governance. Use for "write a plan", "review this build doc", "apply our SWE standards", or "is this plan ready to build"; also apply before drafting a project plan. Grades grounded recon, minimal scope, diagnosis, blast radius, and verifiable acceptance. This is a planning rubric, not a debugging or execution pipeline.
---

# SWE

Vibe the build; engineer the plan. This lens is the discipline that lets a fast v1.x ship without becoming a liability.

A governance overlay for **build/spec documents** — the "build v1.x" doc, the implementation spec, the architecture RFC. It does not debug code or pick a tradeoff in the moment; it reads the *plan* and asks whether the plan already embodies the engineering standards before a single line is written. Run it two ways: as an **authoring gate** (write the doc against it) or as a **review rubric** (read a doc, emit findings + a verdict). The whole bet: most plans fail not on the feature but on the five things below, smuggled past in prose — starting with Pillar 0, where the plan is grounded (or not) in the system as it actually exists.

## Pillar 0: Recon — is the plan grounded in a system anyone actually read?

The four pillars grade what the document *says*. Pillar 0 grades its **provenance**: was it written against the system as it exists, or from the prompt plus three grepped files? This pillar is about evidence, not consequences — what breaks when a *step* runs is Blast's job, below.

- [ ] The current system was traced before the first plan heading: entry points and call paths in, every read *and write* site of the state involved, the contracts crossed, the failure and rollback paths today.
- [ ] Claims about what the change touches cite code somebody read — `file:line`, not "various downstream."
- [ ] What could not be verified is listed as an explicit unknown with the command or file that would settle it, never smoothed into the findings.

**Applicability first.** Pillar 0 does not apply to greenfield work, a non-code plan, or a change contained to files the doc already quotes — mark it N/A and say why. Where it does apply, grade the *evidence*, not the artifact: a [recon](../recon/SKILL.md) Recon Map is the standard form, but a trace embedded in the doc or supplied by the author counts. **Block** only when the doc makes claims about an existing system that nothing behind it verifies; a thin trace on a genuinely small change is a **Fix**, not a Block.

**Pillar 0 feeds Blast; it does not satisfy it.** The trace establishes the *current-state* radius — who depends today on what the plan touches. Blast then asks what each proposed step *adds*: new systems, new data, new people, the shield, the tripwire, the undo class. Copying the map's radius into the Blast section unchanged understates the plan's own impact and fails Blast on its own terms.

## The four pillars

Each pillar is a lens on the document. A v1.x doc that satisfies a pillar contains the thing explicitly; a doc that "implies" it fails the pillar — implied is unbuilt.

### 1. Minimal (Ponytail) — does the plan earn each part it adds?

The plan's default answer to "add a thing" is *no*. Scope, dependencies, and abstractions are all liabilities until justified in the doc.

- [ ] Every new component answers "does this need to exist?" (YAGNI) — speculative scope is cut or deferred, not built.
- [ ] Sourcing ladder is honored to minimize mechanism, not requirements: stdlib → native platform feature → already-installed dep → one line of our own. A new dep names what it buys that the rung above does not. (Security and observability requirements are never simplified away, only implemented via the laziest viable mechanism).
- [ ] No premature abstraction — the plugin layer / framework / generic engine is justified by ≥2 concrete present uses, not one hypothetical future one.
- [ ] Bias is stated: delete > add, boring > clever, shortest diff that works. A complexity cap is named (e.g. stdlib-only, ~600-line ceiling) where it applies.

*Planning translation:* this is the editor pass on scope. Most v1.x bloat is decided here, in the doc, long before code.

### 2. Diagnosable (Mantra) — does the plan say how it will fail and be found?

A build doc that provisions zero observability is a debugging session deferred to production. Bake the diagnosis path into v1.x, not v1.next.

- [ ] Instrumentation is right-sized but explicit: a single actionable error log is better than an unread ELK stack, but silent failures are blocked. The plan names the exact log, metric, or alert that fires when it breaks.
- [ ] Every iterate/retry loop has a **stop condition** (e.g. 5-failure hard stop, 10-total cap). An unbounded "retry until it works" is a defect in the plan.
- [ ] Failures are made reproducible: the plan names how a failure is repro'd, and treats intermittent failure as a *signal* (concurrency / ordering / env / TOCTOU), not noise to retry away.
- [ ] State changes are auditable — append-only event log over in-place mutation where the history matters.
- [ ] **The plan names debug-mantra as its execution-time debugging protocol** — "we'll figure it out when it breaks" is a Diagnosable failure.

*Planning translation:* the runtime debugging ritual, pulled forward. If the doc can't say how you'll see it break, you'll see it break in prod.

### 3. Blast — does the plan price its irreversible moves before committing?

For every wide-impact or hard-to-undo step, the doc must already carry the cost. Don't dress a one-way door as a tweak.

- [ ] Each risky step names its **undo class**: easy / costly / one-way door. One-way doors are flagged, never silent.
- [ ] **Blast radius** is named — the exact systems, data, and people that break if this step goes wrong (not "various downstream").
- [ ] A **shield** is specified — flag, adapter, pilot/canary, dual-write, or an explicit "none."
- [ ] A **tripwire** exists for anything costly or one-way: *how* you'll know to pull it and *by when* (the point of no return). A shield with no tripwire is a brake with no warning light.

For the full per-decision accounting, defer to the **blast-radius** skill — this pillar only enforces that the v1.x doc *contains* that accounting for its irreversible steps.

### 4. Proof (Done) — can the plan prove it's finished, separately from claiming it?

Editor and grader are different roles. The plan must define "done" in terms something other than the author can check.

- [ ] Every task has a **measurable done-criterion** — a checkable output or metric, not "works" / "improved" / "robust."
- [ ] Tests are specified *and the plan requires they actually run* — "tests pass" means an execution artifact, not an assertion.
- [ ] **No orphan tasks**: every step maps to a success criterion, and every success criterion is covered by a step.
- [ ] **Closed loop**: For medium/large efforts, backend/data work must explicitly connect to a user-facing UI plane or final consumer. Fetching data without surfacing it to the user is an incomplete loop.
- [ ] **Observed vs. predicted is kept separate** — the doc never launders a projection ("this will reduce load 40%") as evidence. Predictions are labeled as such.

*Planning translation:* PlanProof's editor/grader separation at document scale. The grader reads only what's written, not what the author meant.

## House invariants

Non-negotiable conventions a v1.x doc must satisfy regardless of pillar. These are cheap to check and expensive to skip.

- [ ] **FSM threshold** — model an explicit state machine only past ~4 states; below that a flag or enum is leaner. Past it, an ad-hoc tangle of booleans is the defect.
- [ ] **Single write path** — one writer per piece of state. Multiple write paths to the same table/file are a race waiting to happen; name the single path.
- [ ] **Append-only event log** only when audit or history is an explicit business requirement (JSONL or equivalent); otherwise, simple in-place updates are the default.
- [ ] **UTC-only** time handling end to end; local time only at the display edge. "Nightly," "daily," "expires in 24h" all imply a timezone — pin it.
- [ ] **Crash-safe / idempotent jobs** — cron and background work are resumable and safe to run twice. A job that corrupts state on a mid-run crash is unshipped.
- [ ] **Checklist standard** — actionable items use the `- [ ]` hyphen prefix in GitHub-flavored Markdown, never bare `[ ]` in tables or lists.
- [ ] **Agent contract current** — for agent-built work, AGENTS.md / CLAUDE.md exists and matches the plan (conventions, loop caps, honesty constraints). The project's AGENTS.md must name SOLID compliance as a coding standard; if it doesn't, the plan has no enforceable code-design contract.

## Zero-Downtime Expand-Contract Schema & State Migration Rubric

When planning online schema changes, state re-encodings, or persistent data migrations across rolling deployments or mixed-version clients, the plan must budget lock/backfill rates, define stop/rollback tripwires, and enforce the 6-stage lifecycle:

1. **Stage 1 — Expand:** Add the new column, field, or data store as nullable or optional, with concurrent write synchronization in place so new writes populate both shapes without breaking existing readers.
2. **Stage 2 — Backfill & Continuous Sync:** Execute an idempotent, rate-limited background backfill. Any concurrent updates occurring during the backfill and mixed-version window MUST reach the new representation with an explicit conflict/ordering strategy.
3. **Stage 3 — Convergence Gate:** Run an automated parity/reconciliation assertion verifying data convergence across old and new representations before cutting over read traffic.
4. **Stage 4 — Switch Reads:** Redirect query and read paths to the new representation, retaining graceful fallback to the legacy shape if read errors occur.
5. **Stage 5 — Dual-Write & Mixed-Version Support:** Continue bidirectional synchronization / updating both representations for every representation still read by active versions, offline clients, or needed by application rollback throughout the entire mixed-version window.
6. **Stage 6 — Contract & Retire:** Ending legacy updates and dropping legacy fields/columns is strictly gated on:
   - (a) Full retirement and migration of all legacy writers.
   - (b) Full retirement of all legacy readers.
   - (c) Full retirement of delayed, queued, or asynchronous consumers.
   - (d) Closure of the application rollback window (or verified reverse synchronization if rollback occurs).

---

## How this differs from the sibling skills

- **swe** — "Does this *plan* embody our engineering standards before we build?" The standard/rubric, applied to a whole document.
- **recon** — "What is actually there?" The read-only trace of the current system that Pillar 0 grades the doc against. It supplies the current-state radius; Blast extends that radius per proposed step. Run recon first in author mode when the plan changes an existing system.
- **phase-0-spike** (an external workflow at `~/.claude/workflows/phase-0-spike.js`, not a skill in this repo) — the deep seam map, contract owners, and rollout invariants for a refactor that is already committed to. `recon` is the cheap universal pass before any plan; phase-0-spike is the expensive one after the refactor is approved. A v1.x doc for a subsystem refactor cites one or the other, never neither.
- **plan-adversarial-serial** — the *pipeline* (generate → review → revise → review → judge). It is the machinery; `swe` is one of the standards the machinery can enforce. Compose them: run the adversarial pipeline with `swe` as the lens content.
- **blast-radius** — "How big is *this one decision* and what breaks?" `swe`'s Blast pillar defers per-decision accounting to it.
- **iron-triangle** — "Which of speed/cost/quality is *this choice* trading?" When a plan forces fast/cheap/good tension, hand that node to it.
- **debug-mantra** — the four-step runtime debugging discipline (reproduce → fail path → falsify → breadcrumb). Diagnosable enforces the plan names it; debug-mantra governs live execution — composing across the doc/session boundary.
- **take-a-step-back** — "Is this the right problem/frame at all?" Runs *before* there is a plan to govern.
- **bottom-line** / **linear** — compress or sequence output. `swe` evaluates a plan's substance; those reshape its presentation.

Reach for `swe` the moment there is a build/spec document to hold to a standard — authoring one or judging one.

## How to apply

**Author mode** — you are writing the v1.x doc. Clear Pillar 0 first (run recon, or state why it was skipped), then use the four pillars and house invariants as the doc's skeleton: each feature passes Minimal before it earns a section; each risky step ships with its Blast block; each task ships with its Proof criterion. The lens is the gate, not a later edit.

**Review mode** — you are handed a v1.x doc. Walk Pillar 0, then the four pillars, then the invariants. For each gap, emit one finding keyed to the doc location (`§section`, or `file:line` for code-adjacent specs), tagged by severity, with the *cheapest* fix first. Close with a verdict. Do not rewrite the doc unless asked — surface the checkable gaps and let the author act.

## Project plan scaffold (Author mode)

When the ask is "write a project plan" / "write a plan" (authoring, not reviewing), clear Pillar 0 first, build the doc against the four pillars **and** lay it out in the fixed structure below. The structure is load-bearing, not decoration: the status table forces an honest "where are we" at a glance, the Table of contents keeps a long plan navigable, observable checklist items *are* the Proof done-criteria, and the per-phase QA checklist is the grader pass made mechanical. Implied is unbuilt — so every field below is written down, not assumed.

Required order, top to bottom: **frontmatter → status table → table of contents → phases (each with observable todos) → per-phase QA checklist**.

````markdown
---
title: <Project> — Build Plan
status: Not started | In progress | Blocked | Shipped
owner: <name>
created: <YYYY-MM-DD>   # UTC
updated: <YYYY-MM-DD>   # UTC — bump every time the plan changes
reversibility: Easy | Costly | One-way door — <one line of why>
---

# <Project> — Build Plan

| Most recently completed phase | What's next |
| --- | --- |
| — (not started) | Phase 1: <name> |

## Table of contents
- [Phase 1: <name>](#phase-1-name)
- [Phase 2: <name>](#phase-2-name)
- [Phase 3: <name>](#phase-3-name)

## Phase 1: <name>
**Goal:** <one observable outcome this phase delivers — not "work on X">

- [ ] <observable todo: names a checkable output or artifact>
- [ ] <observable todo>
- [ ] <observable todo>

### Phase 1 — QA checklist
- [ ] Every todo above produced its checkable output (no orphan tasks)
- [ ] Tests written **and run** — point to the execution artifact, not an assertion
- [ ] Diagnosable: logs + correlation id present; every loop has a stop condition
- [ ] Blast: each risky step names undo-class + shield + tripwire (or explicit "none")
- [ ] Status table and `updated:` date refreshed before this phase is marked done

## Phase 2: <name>
...
````

Filling it:

- **Frontmatter** — the at-a-glance contract. Keep `status`, `updated`, and `reversibility` honest; a stale `updated` date is the first sign the plan drifted from reality.
- **Status table** — exactly two columns, one row. It is the single source of truth for "where are we"; update it as the *last* step of finishing a phase, never before. Don't expand it into a multi-row log — that's what phases are for.
- **Phases** — split by observable milestone, not by calendar. Apply the Minimal pillar to phase count too: only as many phases as the work earns. Each phase has one `**Goal:**` line stating the outcome it delivers.
- **Observable todos** — every `- [ ]` names a checkable output, not an activity. "Add retry cap of 5 to the reconciler loop" passes; "improve reliability" fails. Use the `- [ ]` hyphen prefix (house Checklist standard), never bare `[ ]`.
- **Per-phase QA checklist** — closes each phase against the four pillars. It is Proof's editor/grader separation per phase: the boxes are checked by running things, not by the author asserting done. A phase isn't complete until its QA checklist is.

## Output format (Review mode)

Lead with the verdict in one line. Then findings, ordered by severity, then quick wins first within a severity. Keep it tight — clean plans get a short list, not a manufactured one.

**Verdict:** **Ship** · **Ship with conditions** · **Block** — [one sentence: the load-bearing reason].

**Findings:**

| Loc | Pillar | Severity | What breaks | Cheapest fix |
| --- | --- | --- | --- | --- |
| §x.y | Blast | Block | One-way migration with no rollback named | Add a dual-write window + a row-count tripwire before cutover |
| §x.z | Proof | Fix | "Improves sync" has no done-criterion | State the measurable signal (e.g. drift count → 0 over 3 runs) |

Severity: **Block** (cannot build safely as written — unguarded one-way door, no done-criteria, unbounded loop) · **Fix** (change before v1.x ships) · **Note** (improvement, optional).

**Quick wins:** [the 1–3 findings fixable in a line of doc, listed as `- [ ]` so the author can tick them off.]

## Principles

**Implied is unbuilt.** A plan gets credit only for what it states. "Obviously we'll log it" is a Diagnosable failure; write it down or it won't exist.

**Editor and grader are different roles.** The strongest constraint in the whole lens is Proof's separation: done is defined by something the author can't fudge. Keep them apart.

**Price the one-way doors loudest.** Reversible mistakes are cheap; irreversible ones are the only ones worth slowing down for. A tweak that can't be undone is not a tweak.

**Cut scope before breaking a corner.** When the plan is overloaded, the Minimal pillar and scope-reduction beat heroics. Defer to `iron-triangle` when the tension is explicitly fast/cheap/good.

**Stop conditions are not optional.** Any loop in the plan — retry, fix-iterate, agent relay — names its cap. Unbounded means undefined.

**Separate what you saw from what you expect.** Observed evidence and predicted behavior are different epistemic objects; a plan that blends them is lying to its future reader.

**Don't manufacture findings.** A genuinely clean v1.x doc gets "Ship" and a short list. The lens enforces a standard, not a quota of objections.

## Example — reviewing a v1.x build doc excerpt

Input (abridged):

> **§3 Nightly order reconciler.** A cron job runs each night to reconcile order state against the upstream system. For each order it pulls upstream status and updates `wp_orders` to match. On mismatch it retries until the write succeeds. This makes order state reliable.

Output:

> **Verdict:** **Block** — a nightly DELETE/UPDATE against the orders table with an unbounded retry, no tripwire, and no measurable "reliable" can corrupt order state with no way to know or stop it.
>
> **Findings:**
>
> | Loc | Pillar | Severity | What breaks | Cheapest fix |
> | --- | --- | --- | --- | --- |
> | §3 | Diagnosable | Block | "retries until the write succeeds" is an unbounded loop | Add a 5-failure hard stop / 10-total cap, then dead-letter the order |
> | §3 | Blast | Block | Bulk overwrite of `wp_orders` is costly-to-one-way with no shield/tripwire | Run in observe mode first; add a row-count + mismatch-rate tripwire before any write mode |
> | §3 | Proof | Fix | "makes order state reliable" has no done-criterion | Define it: drift count → 0 across 3 consecutive runs, logged |
> | §3 | House (UTC) | Fix | "each night" has no timezone | Pin the schedule to UTC; document the local display offset separately |
> | §3 | House (write path) | Note | Reconciler is a second writer to `wp_orders` | Name the single write path, or gate the reconciler behind the same one |
>
> **Quick wins:**
> - [ ] Add the loop cap (§3) — one clause.
> - [ ] Pin "each night" to UTC (§3) — one word.
> - [ ] Replace "reliable" with the drift-count criterion (§3) — one sentence.

## What success looks like

The author sees, before any code exists, exactly where the plan is a wish rather than a build: the loop with no cap, the migration with no rollback, the task that can't prove it's done. The best outcome is a v1.x doc that ships fast *because* its risky parts were priced up front — not one that ships fast and pays later.
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
| 1. Reproduce | Runnable repro of the failure. | **Measured ground truth at plan time.** Every count, `file:line`, and live-state claim in the plan is re-run now, not remembered — a "measured, not assumed" evidence table (claim · command run · observed value) is the shape. A recalled repo state is hypothesis-zero. |
| 2. Fail path | Trace the code that breaks. | **Trace the real path the plan changes**, before proposing: walk it and enumerate every caller and surface it touches. A criterion about a path nobody traced is a guess wearing a checkbox. |
| 3. Falsify | Disprove the root-cause hypothesis. | **Falsify the acceptance criteria.** Each criterion must name how it fails — a criterion that cannot fail is decorative, and one an empty input satisfies passes vacuously. Specify the red control *and where its evidence will land* (`test/baselines/` negative-control pattern). Rank 3–5 alternatives for the load-bearing design choice and name the strongest counterargument (an explicit "Open question for the reviewers" block is the pattern). |
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

codex
> **Mantra:**
> 1. **First is reproducibility.** Can the issue — or the artifact — be reproduced or observed reliably?
> 2. **Know the fail path.** Debugger first; then source trace + knob enumeration; then in-code instrumentation.
> 3. **Question your hypothesis.** What would disprove it?
> 4. **Every run is a breadcrumb.** Cross-reference all of them.

exec
/bin/zsh -lc "cat GUIDING-PRINCIPLES.md; cat /Users/noelsaw/.codex/skills/swe/SKILL.md; sed -n '1,120p' PROJECT/PDDA.md" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-17340-oelbhd71
exec
/bin/zsh -lc "nl -ba relay-automation/relay-turn-lib.sh | sed -n '770,1085p'; nl -ba relay-automation/relay-turn-lib.sh | sed -n '1090,1425p'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-17340-oelbhd71
 succeeded in 0ms:
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
---
name: swe
description: Apply software-engineering standards when authoring or reviewing project plans, build/spec/PRD documents, architecture RFCs, or agent governance. Use for "write a plan", "review this build doc", "apply our SWE standards", or "is this plan ready to build"; also apply before drafting a project plan. Grades grounded recon, minimal scope, diagnosis, blast radius, and verifiable acceptance. This is a planning rubric, not a debugging or execution pipeline.
---

# SWE

Vibe the build; engineer the plan. This lens is the discipline that lets a fast v1.x ship without becoming a liability.

A governance overlay for **build/spec documents** — the "build v1.x" doc, the implementation spec, the architecture RFC. It does not debug code or pick a tradeoff in the moment; it reads the *plan* and asks whether the plan already embodies the engineering standards before a single line is written. Run it two ways: as an **authoring gate** (write the doc against it) or as a **review rubric** (read a doc, emit findings + a verdict). The whole bet: most plans fail not on the feature but on the five things below, smuggled past in prose — starting with Pillar 0, where the plan is grounded (or not) in the system as it actually exists.

## Pillar 0: Recon — is the plan grounded in a system anyone actually read?

The four pillars grade what the document *says*. Pillar 0 grades its **provenance**: was it written against the system as it exists, or from the prompt plus three grepped files? This pillar is about evidence, not consequences — what breaks when a *step* runs is Blast's job, below.

- [ ] The current system was traced before the first plan heading: entry points and call paths in, every read *and write* site of the state involved, the contracts crossed, the failure and rollback paths today.
- [ ] Claims about what the change touches cite code somebody read — `file:line`, not "various downstream."
- [ ] What could not be verified is listed as an explicit unknown with the command or file that would settle it, never smoothed into the findings.

**Applicability first.** Pillar 0 does not apply to greenfield work, a non-code plan, or a change contained to files the doc already quotes — mark it N/A and say why. Where it does apply, grade the *evidence*, not the artifact: a [recon](../recon/SKILL.md) Recon Map is the standard form, but a trace embedded in the doc or supplied by the author counts. **Block** only when the doc makes claims about an existing system that nothing behind it verifies; a thin trace on a genuinely small change is a **Fix**, not a Block.

**Pillar 0 feeds Blast; it does not satisfy it.** The trace establishes the *current-state* radius — who depends today on what the plan touches. Blast then asks what each proposed step *adds*: new systems, new data, new people, the shield, the tripwire, the undo class. Copying the map's radius into the Blast section unchanged understates the plan's own impact and fails Blast on its own terms.

## The four pillars

Each pillar is a lens on the document. A v1.x doc that satisfies a pillar contains the thing explicitly; a doc that "implies" it fails the pillar — implied is unbuilt.

### 1. Minimal (Ponytail) — does the plan earn each part it adds?

The plan's default answer to "add a thing" is *no*. Scope, dependencies, and abstractions are all liabilities until justified in the doc.

- [ ] Every new component answers "does this need to exist?" (YAGNI) — speculative scope is cut or deferred, not built.
- [ ] Sourcing ladder is honored to minimize mechanism, not requirements: stdlib → native platform feature → already-installed dep → one line of our own. A new dep names what it buys that the rung above does not. (Security and observability requirements are never simplified away, only implemented via the laziest viable mechanism).
- [ ] No premature abstraction — the plugin layer / framework / generic engine is justified by ≥2 concrete present uses, not one hypothetical future one.
- [ ] Bias is stated: delete > add, boring > clever, shortest diff that works. A complexity cap is named (e.g. stdlib-only, ~600-line ceiling) where it applies.

*Planning translation:* this is the editor pass on scope. Most v1.x bloat is decided here, in the doc, long before code.

### 2. Diagnosable (Mantra) — does the plan say how it will fail and be found?

A build doc that provisions zero observability is a debugging session deferred to production. Bake the diagnosis path into v1.x, not v1.next.

- [ ] Instrumentation is right-sized but explicit: a single actionable error log is better than an unread ELK stack, but silent failures are blocked. The plan names the exact log, metric, or alert that fires when it breaks.
- [ ] Every iterate/retry loop has a **stop condition** (e.g. 5-failure hard stop, 10-total cap). An unbounded "retry until it works" is a defect in the plan.
- [ ] Failures are made reproducible: the plan names how a failure is repro'd, and treats intermittent failure as a *signal* (concurrency / ordering / env / TOCTOU), not noise to retry away.
- [ ] State changes are auditable — append-only event log over in-place mutation where the history matters.
- [ ] **The plan names debug-mantra as its execution-time debugging protocol** — "we'll figure it out when it breaks" is a Diagnosable failure.

*Planning translation:* the runtime debugging ritual, pulled forward. If the doc can't say how you'll see it break, you'll see it break in prod.

### 3. Blast — does the plan price its irreversible moves before committing?

For every wide-impact or hard-to-undo step, the doc must already carry the cost. Don't dress a one-way door as a tweak.

- [ ] Each risky step names its **undo class**: easy / costly / one-way door. One-way doors are flagged, never silent.
- [ ] **Blast radius** is named — the exact systems, data, and people that break if this step goes wrong (not "various downstream").
- [ ] A **shield** is specified — flag, adapter, pilot/canary, dual-write, or an explicit "none."
- [ ] A **tripwire** exists for anything costly or one-way: *how* you'll know to pull it and *by when* (the point of no return). A shield with no tripwire is a brake with no warning light.

For the full per-decision accounting, defer to the **blast-radius** skill — this pillar only enforces that the v1.x doc *contains* that accounting for its irreversible steps.

### 4. Proof (Done) — can the plan prove it's finished, separately from claiming it?

Editor and grader are different roles. The plan must define "done" in terms something other than the author can check.

- [ ] Every task has a **measurable done-criterion** — a checkable output or metric, not "works" / "improved" / "robust."
- [ ] Tests are specified *and the plan requires they actually run* — "tests pass" means an execution artifact, not an assertion.
- [ ] **No orphan tasks**: every step maps to a success criterion, and every success criterion is covered by a step.
- [ ] **Closed loop**: For medium/large efforts, backend/data work must explicitly connect to a user-facing UI plane or final consumer. Fetching data without surfacing it to the user is an incomplete loop.
- [ ] **Observed vs. predicted is kept separate** — the doc never launders a projection ("this will reduce load 40%") as evidence. Predictions are labeled as such.

*Planning translation:* PlanProof's editor/grader separation at document scale. The grader reads only what's written, not what the author meant.

## House invariants

Non-negotiable conventions a v1.x doc must satisfy regardless of pillar. These are cheap to check and expensive to skip.

- [ ] **FSM threshold** — model an explicit state machine only past ~4 states; below that a flag or enum is leaner. Past it, an ad-hoc tangle of booleans is the defect.
- [ ] **Single write path** — one writer per piece of state. Multiple write paths to the same table/file are a race waiting to happen; name the single path.
- [ ] **Append-only event log** only when audit or history is an explicit business requirement (JSONL or equivalent); otherwise, simple in-place updates are the default.
- [ ] **UTC-only** time handling end to end; local time only at the display edge. "Nightly," "daily," "expires in 24h" all imply a timezone — pin it.
- [ ] **Crash-safe / idempotent jobs** — cron and background work are resumable and safe to run twice. A job that corrupts state on a mid-run crash is unshipped.
- [ ] **Checklist standard** — actionable items use the `- [ ]` hyphen prefix in GitHub-flavored Markdown, never bare `[ ]` in tables or lists.
- [ ] **Agent contract current** — for agent-built work, AGENTS.md / CLAUDE.md exists and matches the plan (conventions, loop caps, honesty constraints). The project's AGENTS.md must name SOLID compliance as a coding standard; if it doesn't, the plan has no enforceable code-design contract.

## Zero-Downtime Expand-Contract Schema & State Migration Rubric

When planning online schema changes, state re-encodings, or persistent data migrations across rolling deployments or mixed-version clients, the plan must budget lock/backfill rates, define stop/rollback tripwires, and enforce the 6-stage lifecycle:

1. **Stage 1 — Expand:** Add the new column, field, or data store as nullable or optional, with concurrent write synchronization in place so new writes populate both shapes without breaking existing readers.
2. **Stage 2 — Backfill & Continuous Sync:** Execute an idempotent, rate-limited background backfill. Any concurrent updates occurring during the backfill and mixed-version window MUST reach the new representation with an explicit conflict/ordering strategy.
3. **Stage 3 — Convergence Gate:** Run an automated parity/reconciliation assertion verifying data convergence across old and new representations before cutting over read traffic.
4. **Stage 4 — Switch Reads:** Redirect query and read paths to the new representation, retaining graceful fallback to the legacy shape if read errors occur.
5. **Stage 5 — Dual-Write & Mixed-Version Support:** Continue bidirectional synchronization / updating both representations for every representation still read by active versions, offline clients, or needed by application rollback throughout the entire mixed-version window.
6. **Stage 6 — Contract & Retire:** Ending legacy updates and dropping legacy fields/columns is strictly gated on:
   - (a) Full retirement and migration of all legacy writers.
   - (b) Full retirement of all legacy readers.
   - (c) Full retirement of delayed, queued, or asynchronous consumers.
   - (d) Closure of the application rollback window (or verified reverse synchronization if rollback occurs).

---

## How this differs from the sibling skills

- **swe** — "Does this *plan* embody our engineering standards before we build?" The standard/rubric, applied to a whole document.
- **recon** — "What is actually there?" The read-only trace of the current system that Pillar 0 grades the doc against. It supplies the current-state radius; Blast extends that radius per proposed step. Run recon first in author mode when the plan changes an existing system.
- **phase-0-spike** (an external workflow at `~/.claude/workflows/phase-0-spike.js`, not a skill in this repo) — the deep seam map, contract owners, and rollout invariants for a refactor that is already committed to. `recon` is the cheap universal pass before any plan; phase-0-spike is the expensive one after the refactor is approved. A v1.x doc for a subsystem refactor cites one or the other, never neither.
- **plan-adversarial-serial** — the *pipeline* (generate → review → revise → review → judge). It is the machinery; `swe` is one of the standards the machinery can enforce. Compose them: run the adversarial pipeline with `swe` as the lens content.
- **blast-radius** — "How big is *this one decision* and what breaks?" `swe`'s Blast pillar defers per-decision accounting to it.
- **iron-triangle** — "Which of speed/cost/quality is *this choice* trading?" When a plan forces fast/cheap/good tension, hand that node to it.
- **debug-mantra** — the four-step runtime debugging discipline (reproduce → fail path → falsify → breadcrumb). Diagnosable enforces the plan names it; debug-mantra governs live execution — composing across the doc/session boundary.
- **take-a-step-back** — "Is this the right problem/frame at all?" Runs *before* there is a plan to govern.
- **bottom-line** / **linear** — compress or sequence output. `swe` evaluates a plan's substance; those reshape its presentation.

Reach for `swe` the moment there is a build/spec document to hold to a standard — authoring one or judging one.

## How to apply

**Author mode** — you are writing the v1.x doc. Clear Pillar 0 first (run recon, or state why it was skipped), then use the four pillars and house invariants as the doc's skeleton: each feature passes Minimal before it earns a section; each risky step ships with its Blast block; each task ships with its Proof criterion. The lens is the gate, not a later edit.

**Review mode** — you are handed a v1.x doc. Walk Pillar 0, then the four pillars, then the invariants. For each gap, emit one finding keyed to the doc location (`§section`, or `file:line` for code-adjacent specs), tagged by severity, with the *cheapest* fix first. Close with a verdict. Do not rewrite the doc unless asked — surface the checkable gaps and let the author act.

## Project plan scaffold (Author mode)

When the ask is "write a project plan" / "write a plan" (authoring, not reviewing), clear Pillar 0 first, build the doc against the four pillars **and** lay it out in the fixed structure below. The structure is load-bearing, not decoration: the status table forces an honest "where are we" at a glance, the Table of contents keeps a long plan navigable, observable checklist items *are* the Proof done-criteria, and the per-phase QA checklist is the grader pass made mechanical. Implied is unbuilt — so every field below is written down, not assumed.

Required order, top to bottom: **frontmatter → status table → table of contents → phases (each with observable todos) → per-phase QA checklist**.

````markdown
---
title: <Project> — Build Plan
status: Not started | In progress | Blocked | Shipped
owner: <name>
created: <YYYY-MM-DD>   # UTC
updated: <YYYY-MM-DD>   # UTC — bump every time the plan changes
reversibility: Easy | Costly | One-way door — <one line of why>
---

# <Project> — Build Plan

| Most recently completed phase | What's next |
| --- | --- |
| — (not started) | Phase 1: <name> |

## Table of contents
- [Phase 1: <name>](#phase-1-name)
- [Phase 2: <name>](#phase-2-name)
- [Phase 3: <name>](#phase-3-name)

## Phase 1: <name>
**Goal:** <one observable outcome this phase delivers — not "work on X">

- [ ] <observable todo: names a checkable output or artifact>
- [ ] <observable todo>
- [ ] <observable todo>

### Phase 1 — QA checklist
- [ ] Every todo above produced its checkable output (no orphan tasks)
- [ ] Tests written **and run** — point to the execution artifact, not an assertion
- [ ] Diagnosable: logs + correlation id present; every loop has a stop condition
- [ ] Blast: each risky step names undo-class + shield + tripwire (or explicit "none")
- [ ] Status table and `updated:` date refreshed before this phase is marked done

## Phase 2: <name>
...
````

Filling it:

- **Frontmatter** — the at-a-glance contract. Keep `status`, `updated`, and `reversibility` honest; a stale `updated` date is the first sign the plan drifted from reality.
- **Status table** — exactly two columns, one row. It is the single source of truth for "where are we"; update it as the *last* step of finishing a phase, never before. Don't expand it into a multi-row log — that's what phases are for.
- **Phases** — split by observable milestone, not by calendar. Apply the Minimal pillar to phase count too: only as many phases as the work earns. Each phase has one `**Goal:**` line stating the outcome it delivers.
- **Observable todos** — every `- [ ]` names a checkable output, not an activity. "Add retry cap of 5 to the reconciler loop" passes; "improve reliability" fails. Use the `- [ ]` hyphen prefix (house Checklist standard), never bare `[ ]`.
- **Per-phase QA checklist** — closes each phase against the four pillars. It is Proof's editor/grader separation per phase: the boxes are checked by running things, not by the author asserting done. A phase isn't complete until its QA checklist is.

## Output format (Review mode)

Lead with the verdict in one line. Then findings, ordered by severity, then quick wins first within a severity. Keep it tight — clean plans get a short list, not a manufactured one.

**Verdict:** **Ship** · **Ship with conditions** · **Block** — [one sentence: the load-bearing reason].

**Findings:**

| Loc | Pillar | Severity | What breaks | Cheapest fix |
| --- | --- | --- | --- | --- |
| §x.y | Blast | Block | One-way migration with no rollback named | Add a dual-write window + a row-count tripwire before cutover |
| §x.z | Proof | Fix | "Improves sync" has no done-criterion | State the measurable signal (e.g. drift count → 0 over 3 runs) |

Severity: **Block** (cannot build safely as written — unguarded one-way door, no done-criteria, unbounded loop) · **Fix** (change before v1.x ships) · **Note** (improvement, optional).

**Quick wins:** [the 1–3 findings fixable in a line of doc, listed as `- [ ]` so the author can tick them off.]

## Principles

**Implied is unbuilt.** A plan gets credit only for what it states. "Obviously we'll log it" is a Diagnosable failure; write it down or it won't exist.

**Editor and grader are different roles.** The strongest constraint in the whole lens is Proof's separation: done is defined by something the author can't fudge. Keep them apart.

**Price the one-way doors loudest.** Reversible mistakes are cheap; irreversible ones are the only ones worth slowing down for. A tweak that can't be undone is not a tweak.

**Cut scope before breaking a corner.** When the plan is overloaded, the Minimal pillar and scope-reduction beat heroics. Defer to `iron-triangle` when the tension is explicitly fast/cheap/good.

**Stop conditions are not optional.** Any loop in the plan — retry, fix-iterate, agent relay — names its cap. Unbounded means undefined.

**Separate what you saw from what you expect.** Observed evidence and predicted behavior are different epistemic objects; a plan that blends them is lying to its future reader.

**Don't manufacture findings.** A genuinely clean v1.x doc gets "Ship" and a short list. The lens enforces a standard, not a quota of objections.

## Example — reviewing a v1.x build doc excerpt

Input (abridged):

> **§3 Nightly order reconciler.** A cron job runs each night to reconcile order state against the upstream system. For each order it pulls upstream status and updates `wp_orders` to match. On mismatch it retries until the write succeeds. This makes order state reliable.

Output:

> **Verdict:** **Block** — a nightly DELETE/UPDATE against the orders table with an unbounded retry, no tripwire, and no measurable "reliable" can corrupt order state with no way to know or stop it.
>
> **Findings:**
>
> | Loc | Pillar | Severity | What breaks | Cheapest fix |
> | --- | --- | --- | --- | --- |
> | §3 | Diagnosable | Block | "retries until the write succeeds" is an unbounded loop | Add a 5-failure hard stop / 10-total cap, then dead-letter the order |
> | §3 | Blast | Block | Bulk overwrite of `wp_orders` is costly-to-one-way with no shield/tripwire | Run in observe mode first; add a row-count + mismatch-rate tripwire before any write mode |
> | §3 | Proof | Fix | "makes order state reliable" has no done-criterion | Define it: drift count → 0 across 3 consecutive runs, logged |
> | §3 | House (UTC) | Fix | "each night" has no timezone | Pin the schedule to UTC; document the local display offset separately |
> | §3 | House (write path) | Note | Reconciler is a second writer to `wp_orders` | Name the single write path, or gate the reconciler behind the same one |
>
> **Quick wins:**
> - [ ] Add the loop cap (§3) — one clause.
> - [ ] Pin "each night" to UTC (§3) — one word.
> - [ ] Replace "reliable" with the drift-count criterion (§3) — one sentence.

## What success looks like

The author sees, before any code exists, exactly where the plan is a wish rather than a build: the loop with no cap, the migration with no rollback, the task that can't prove it's done. The best outcome is a v1.x doc that ships fast *because* its risky parts were priced up front — not one that ships fast and pays later.
# Project-Driven Doc Automation (PDDA)

Canonical development: [XYZ Forge](https://github.com/HiQS-Labs/XYZ-forge).
The shared contract below applies to installed copies; repo-specific adoption policy lives in the target’s startup docs.

PDDA is the document operating layer for this repo. Its job is to keep project plans, bug-fix docs,
research notes, and roadmap pointers clean enough that an agent can pick up work with minimal drift
and enough structure that routine hygiene can be automated instead of re-decided every session.

The core idea is simple:

- deterministic scripts enforce the parts that should never require judgment
- an LLM reviewer flags structural or planning-quality gaps that are hard to express as regex alone
- `ROADMAP.md` stays a pointer/index, while project detail lives in the individual project docs

## Goals

- Keep `PROJECT/2-WORKING` limited to docs that are truly active.
- Ensure every active doc answers two questions at a glance: what was just completed, and what is next.
- Make phased plans automation-ready by requiring explicit QA gates.
- Prevent plan rot: stale files, missing next steps, hardcoded paths, and hidden scope drift.
- Give agents one repeatable contract for project docs, bug-fix docs, and experimental plans.

## Non-goals

- PDDA does not replace the project docs themselves.
- PDDA does not decide product strategy.
- PDDA does not auto-rewrite nuanced plan content without review.
- PDDA does not turn `ROADMAP.md` into a second execution plan.

## Canonical document model

PDDA assumes four lifecycle buckets:

- `PROJECT/1-INBOX`: new ideas, rough proposals, untriaged notes
- `PROJECT/2-WORKING`: active docs that should be updated as work progresses
- `PROJECT/3-COMPLETED`: completed docs with an outcome
- `PROJECT/4-MISC`: reference, stale, superseded, or abandoned docs

Within that model:

- `ROADMAP.md` is the index of current, completed, attempted, and deferred work
- project detail lives in the individual `PROJECT/**` documents
- a working doc is the canonical source of truth for that effort until it is completed, deferred, or superseded
- `blank.md` placeholders are scaffolding and should be ignored by PDDA checks

## Required contract for active docs

Every doc in `PROJECT/2-WORKING` should have:

1. YAML frontmatter with at least `title`, `status`, `created`, `updated`, `owner`, and `goal`
2. a near-top status table with the exact columns:

```md
## Status

| What was just completed | What's next |
|---|---|
| ... | ... |
```

3. clear phase or work sections if the doc is a plan
4. a table of contents (`## Table of contents`) listing each phase, if the plan is multi-phase — so a
   cold agent can see the full phase span and jump to the live one without scrolling the whole body
5. QA gates or acceptance criteria after each phase if the plan is multi-phase
6. for any discovery or spike phase, its findings written **back into this doc** before its QA gate can
   pass (see [Discovery & spike phases (Memory Injection)](#discovery--spike-phases-memory-injection))
7. repo-relative paths only; no hardcoded absolute local paths
8. before moving to `PROJECT/3-COMPLETED`, a `## Lessons Learned (For Future Agents)` section appended to capture quirks and gotchas

Recommended fields when relevant:

- `related`
- `context_tags` (e.g. `[auth, flaky-tests, build]`)
- `reviewed`
- `branch`
- `non_goals`
- `gh_issue`
- `effort`, `complexity`, `risk`, `phases` — triage ratings; **required for medium-large work** (see
  [Triage ratings for medium-large work](#triage-ratings-for-medium-large-work))

## Quad Concepts (opt-in)

An **opt-in** glance layer, **off by default**. The `## Status` table says *where* the work is; Quad
Concepts says *what* it is — a 5-second read of the core problems a plan tackles and how, so an operator
can see whether the real pain points are covered. (Distinct from `context_tags`: those are for search;
this is for glance.)

When enabled system-wide via the `.pdda-quad` lever (or the `PDDA_QUAD` env var — **orthogonal** to the
enforcement mode), tracked plan docs must carry a `## Quad Concepts` section of **1–4 bullets**,
conventionally right after `## Status`:

```md
## Quad Concepts
- <pain the doc addresses> → <how it addresses it>
```

- **Shape (deterministic):** 1–4 **top-level, non-empty** `-`/`*` bullets in the first `## Quad Concepts`
  section. `pain → fix` phrasing is the convention (nudged by the LLM readiness rubric), not a hard regex.
- **Scope:** `PROJECT/2-WORKING`, `PROJECT/1-INBOX/GH-*.md`, and `PROJECT/3-COMPLETED` (the last keeps a
  glanceable summary for cold-start recall). `PROJECT/4-MISC` is out.
- **Enable:** set `.pdda-quad` to `on` (or `PDDA_QUAD=1`). The enforcement mode still governs whether a
  missing/malformed section merely reports or blocks. **Opt a doc out** with `quad_exempt: true`.
- Enforced by `pdda.sh quad-concepts` (deterministic, structure-only) plus a warn-only readiness rubric.
- `pdda.sh glance` (read-only, always available) rolls up `title + Quad Concepts` across `2-WORKING` for
  a one-screen view of what the active portfolio is addressing.

## Triage ratings for medium-large work

So automation can pick *which* task to pursue without re-reading every plan, every newly recorded
**medium-large** task or project carries four triage fields in its frontmatter:

| Field | Range | Meaning |
|---|---|---|
| `effort` | integer `1`–`5` | how much work — `1` low, `5` highest |
| `complexity` | integer `1`–`5` | how intricate / how many moving parts — `1` low, `5` highest |
| `risk` | integer `1`–`5` | blast radius + uncertainty — `1` safe/contained, `5` one-way-door or unknown |
| `phases` | positive integer | total number of phases in the plan |

```yaml

 succeeded in 0ms:
   770	      rtl_trace "rtl_worktree_begin: node_modules copy failed — turn proceeds without build deps (GH-642)"
   771	    fi
   772	  fi
   773	  rtl_trace "rtl_worktree_begin: WT=$wt"
   774	  for a in "${RTL_ALLOW[@]}"; do       # seed current content (overwrite HEAD versions)
   775	    # GH-30 Phase 3: an ABSOLUTE allowlist entry is the archive relay file — it lives in a DIFFERENT
   776	    # repo, not this RTL_ROOT worktree. Skip it: the agent edits it at its real location and rtl_enforce
   777	    # commits it to the archive. (Keeps seedsig index aligned with the copyback loop, which skips it too.)
   778	    if [[ "$a" == /* ]]; then
   779	      rtl_trace "rtl_worktree_begin: SKIP (archive-absolute) $a"
   780	      continue
   781	    fi
   782	    if [[ -e "$RTL_ROOT/$a" ]]; then
   783	      mkdir -p "$wt/$(dirname "$a")"
   784	      cp -R "$RTL_ROOT/$a" "$wt/$a"
   785	      rtl_trace "rtl_worktree_begin: SEED $a"
   786	    else
   787	      rm -rf "$wt/$a"                  # allowlisted path ALREADY deleted in the host tree → mirror the
   788	                                       # deletion, else the HEAD checkout would resurrect it on copy-back
   789	      rtl_trace "rtl_worktree_begin: SEED-DELETE $a (already absent in ROOT)"
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
   976	      fi
   977	    done
   978	  fi
   979	  rm -f "${wt}.seedsig" "${wt}.artifactsig"   # GH-22 + GH-31: clean up the sidecar signature files
   980	  if git -C "$RTL_ROOT" worktree remove --force "$wt" >/dev/null 2>&1; then
   981	    xyz_write_ops_log_append "git worktree remove" "git -C $RTL_ROOT worktree remove --force $wt"
   982	  else
   983	    rm -rf "$wt"
   984	    xyz_write_ops_log_append "rm force" "rm -rf $wt"
   985	  fi
   986	  git -C "$RTL_ROOT" worktree prune >/dev/null 2>&1 || true
   987	  xyz_write_ops_log_append "git worktree prune" "git -C $RTL_ROOT worktree prune" 
   988	  if [ -n "${RTL_ROOT:-}" ] && [ -f "$RTL_ROOT/utils/py/workspace_manager.py" ]; then
   989	    python3 "$RTL_ROOT/utils/py/workspace_manager.py" deregister --repo "$RTL_ROOT" --path "$wt" >/dev/null 2>&1 || true
   990	  fi
   991	  RTL_WT=""
   992	}
   993	
   994	rtl_turn_prompt() {  # <agent> <relay_file> <task> <allow_csv> [peer]
   995	  local agent="$1" f="$2" task="$3" csv="$4" peer="${5:-}"
   996	  # Name the peer explicitly when known — a live Gemini turn (2026-06-15) released the token to the
   997	  # literal role "Producer" because "the other agent" was unnamed. RELAY_PEER closes that ambiguity.
   998	  local handoff="release --to the other agent (the role named by NEXT in the file)"
   999	  [[ -n "$peer" ]] && handoff="release --to ${peer}"
  1000	  # Emit repo-root-relative EDIT paths (relay file, artifact) so they resolve against the turn's CWD —
  1001	  # which under worktree isolation IS the throwaway worktree. An ABSOLUTE edit path would invite the
  1002	  # model to write straight into RTL_ROOT, bypassing the worktree (Codex review 2026-06-20). RTL_ROOT
  1003	  # is set by rtl_init (always called first). Residual: a sync absolute write the model constructs
  1004	  # itself is still backstopped by rtl_enforce on ROOT (revert + exit 6); an ASYNC one remains the
  1005	  # known process-detachment gap.
  1006	  # The TICK invocation is the EXCEPTION and is deliberately ABSOLUTE + env-pinned: tick is a tool, not
  1007	  # an edit target, and .tick is SHARED coordination state that must resolve to the harness root no
  1008	  # matter the CWD. A bare/`./bin/tick` from a worktree or foreign CWD silently no-ops -> the token
  1009	  # never releases -> deadlock (relay review 2026-06-23 F1). tickroot = the harness clone (where
  1010	  # bin/tick + .tick live), i.e. TICK_REPO_ROOT (exported by the shim), falling back to RTL_ROOT.
  1011	  local root="${RTL_ROOT:-}" tickroot="${TICK_REPO_ROOT:-${RTL_ROOT:-}}" tickbin f_rel csv_rel="" p _a
  1012	  tickbin="$(rtl_tick_bin "$tickroot")"
  1013	  # GH-304: derive the repo-root-relative EDIT path robustly. A plain `${f#"$root/"}` string-strip
  1014	  # silently no-ops when $f and $root arrive in different symlink forms (git's PHYSICAL /private/var
  1015	  # toplevel vs a /var-form path built from $PWD on macOS) — the absolute path then leaks into the
  1016	  # prompt, inviting a write straight into RTL_ROOT past the worktree. Canonicalize both sides to their
  1017	  # physical form before stripping (mirrors rtl_init's RTL_ALLOW normalization), so the seed path
  1018	  # (rtl_worktree_begin) and the prompt path stay in lockstep. Falls back to the raw string strip for a
  1019	  # relative or nonexistent $f — byte-for-byte the prior behaviour for the common same-CWD case.
  1020	  f_rel="${f#"${root:+$root/}"}"
  1021	  if [[ "$f" == /* && -e "$f" ]]; then
  1022	    local _f_dir _f_phys _root_phys
  1023	    _f_dir="$(cd "$(dirname "$f")" 2>/dev/null && pwd -P)"
  1024	    _root_phys="$(cd "$root" 2>/dev/null && pwd -P)"
  1025	    if [[ -n "$_f_dir" && -n "$_root_phys" ]]; then
  1026	      _f_phys="$_f_dir/$(basename "$f")"
  1027	      [[ "$_f_phys" == "$_root_phys"/* ]] && f_rel="${_f_phys#"$_root_phys"/}"
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
  1059	rtl_before() {
  1060	  RTL_BEFORE_HEAD="$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)"
  1061	  # Snapshot the PRE-turn dirty set (raw -z porcelain fields) so enforcement touches only the
  1062	  # agent's OWN changes — never pre-existing ambient WIP in the host repo (field report MBP16 [1]).
  1063	  RTL_BEFORE=()
  1064	  local fld
  1065	  while IFS= read -r -d '' fld; do RTL_BEFORE+=("$fld"); done \
  1066	    < <(git -C "$RTL_ROOT" status --porcelain -z 2>/dev/null)
  1067	
  1068	  # GH-124 QW4: Early Rebase Drift Alert (Option A: zero-lock local tracking ref inspection)
  1069	  local drift_count
  1070	  drift_count="$(git -C "${RTL_ROOT:-.}" rev-list --count HEAD..refs/remotes/origin/development 2>/dev/null || echo 0)"
  1071	  if [ "${drift_count:-0}" -ge 3 ]; then
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
  1181	  RTL_VIOLATION=1
  1182	}
  1183	
  1184	# GH-173 B3 / GH-178 A4 follow-up (code review on PR #184): the claim-trigger and citation regexes
  1185	# are shared by both call sites below — rtl_check_uncited_findings's per-line downgrade, and
  1186	# rtl_has_uncited_claim's read-only predicate (used by consult.sh's A4 stamp) — so the two stay in
  1187	# lockstep on one definition of "claim"/"citation" instead of drifting apart.
  1188	#   RTL_CLAIM_WORD_RE — free-form phrasing a model might use INSTEAD of the [Pass] tag to assert
  1189	#                        correctness. Widened 2026-07-08 from a 3-word list ([Pass]/verified/
  1190	#                        confirmed) — that list let an assertion like "looks good, no issues, ship
  1191	#                        it" bypass the backstop entirely (none of the 3 tokens present), undermining
  1192	#                        the "mechanical, not prompt-compliance-dependent" premise for any vocabulary
  1193	#                        outside that short list. The [Pass] TAG itself is deliberately NOT folded
  1194	#                        into this variable — see the warning below.
  1195	#   RTL_CITATION_RE    — a quoted span ("..."/`...`) or a file:line reference (name:NNN).
  1196	# WARNING — do not add `\[Pass\]` (or any other backslash-escaped literal) to either of these
  1197	# strings. Both are passed to awk via `-v` and matched as a DYNAMIC regex (`line ~ var`); macOS's
  1198	# default /usr/bin/awk ("one true awk") string-unescapes a -v value before compiling it as a regex,
  1199	# which silently turns the literal string \[Pass\] into the bracket EXPRESSION [Pass] — i.e. "any
  1200	# single P, a, or s character" — matching almost every line instead of the literal tag. Caught in
  1201	# review of this very follow-up (the widened-vocabulary tests below false-matched an unrelated
  1202	# [Blocker] line and a bare "RECOMMENDATION: ship" line). Reproduce with:
  1203	#   printf 'xyz\n' | awk -v re='\[Pass\]' '$0 ~ re {print "false match: " $0}'   # prints on macOS awk
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
  1406	        _val_rf="$RTL_ROOT/$_val_rf"
  1407	      fi
  1408	    fi
  1409	    if [[ -f "$_val_rf" ]]; then
  1410	      # Structural relay-block validation applies to /relay threads (which structure rounds under ## Log / ## Setup).
  1411	      # Marathon-drive phase briefs use a distinct lifecycle managed by marathon-drive.
  1412	      if grep -qE '^[[:space:]]*##[[:space:]]*(Log|Setup)' "$_val_rf" 2>/dev/null; then
  1413	        local _val_bin
  1414	        _val_bin="$(rtl_validator_bin "$_val_tickroot")"
  1415	        [[ -z "$_val_bin" ]] && _val_bin="$(rtl_validator_bin "$RTL_ROOT")"
  1416	        if [[ -n "$_val_bin" && -x "$_val_bin" ]]; then
  1417	          local _val_out _val_rc=0
  1418	          _val_out="$("$_val_bin" "$_val_rf" 2>&1)" || _val_rc=$?
  1419	          if (( _val_rc != 0 )); then
  1420	            printf '%s-turn: relay block structural validation failed (exit %d):\n%s\n' "$RTL_TOOL" "$_val_rc" "$_val_out" >&2
  1421	            rtl_log_always "rtl_enforce: VALIDATION_FAILED exit=$_val_rc agent=$agent relay=$_val_rf"
  1422	            exit 8
  1423	          fi
  1424	          rtl_trace "rtl_enforce: relay block structural validation passed for $_val_rf"
  1425	        fi

exec
/bin/zsh -lc "nl -ba relay-automation/new-relay.sh | sed -n '1,165p'; nl -ba skills/relay/SKILL.md | sed -n '210,280p'; nl -ba skills/relay-xyz/SKILL.md | sed -n '580,635p'; nl -ba relay-system/2026-09-17/gh673-final-qa.md | tail -190" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-17340-oelbhd71
 succeeded in 0ms:
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
   116	$fence
   117	$(cat "$ARTIFACT")
   118	$fence
   119	EOF
   120	  elif [[ -n "$ARTIFACT" ]]; then
   121	    cat <<EOF
   122	- Artifact under review: **.relay-artifacts/$art_base** — the read-only path that
   123	  \`relay-drive.sh --artifact-file $ARTIFACT\` seeds into the isolated worktree (read it there; do NOT edit it).
   124	- Reviewer: $REVIEWER   ·   Producer: $PRODUCER
   125	- Started: $TODAY
   126	EOF
   127	  else
   128	    cat <<EOF
   129	- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
   130	- Reviewer: $REVIEWER   ·   Producer: $PRODUCER
   131	- Started: $TODAY
   132	EOF
   133	  fi
   134	
   135	  cat <<EOF
   136	- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_
   137	
   138	## Ground rules
   139	1. This file is the single source of truth. The agents never share memory — read the whole file.
   140	2. Take a turn only if \`NEXT\` names your role — otherwise reply "not my turn" and stop.
   141	3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
   142	4. Stay tight — findings are bullets, not essays. Grade every finding.
   143	5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
   144	6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.
   145	
   146	## Log
   147	
   148	<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
   149	EOF
   150	}
   151	
   152	if (( PRINT )); then
   153	  emit
   154	  exit 0
   155	fi
   156	
   157	# GH-30 Phase 3: when XYZ_ARCHIVE_ROOT is set, default the thread location through the transcript-root
   158	# resolver so a scaffolded thread lands in the archive ($XYZ_ARCHIVE_ROOT/relay-system/<slug>/…) — the
   159	# same redirect the other transcript writers already honor (Phase 2). Unset var → byte-for-byte the
   160	# prior relative "relay-system/$TODAY/$SLUG.md" default (kept so the default path stays cwd-relative).
   161	# An explicit --out still wins (resolver not consulted). The resolver fails loud on a set-but-invalid
   162	# archive, so a bad var never silently writes into the cwd.
   163	if [[ -z "$OUT" ]]; then
   164	  if [[ -n "${XYZ_ARCHIVE_ROOT:-}" ]]; then
   165	    # shellcheck source=relay-turn-lib.sh
   210	1. **TLDR — one line, at the very top.** Round, role, verdict/status, and what happens next: *"Round 2 Reviewer done — Changes requested, 1 Blocker. Producer's turn next."* This **is** the hand-off nudge, just promoted to the first line instead of the last — the human should never have to read past line one to know the result.
   211	2. **One short framing sentence**, in your own voice — *"Reviewing `evidence.py` against the DoD…"* — only if it adds something the TLDR didn't already say. Skip it when it would just restate the TLDR.
   212	3. **If there are findings to report, close with them sorted by grade** — `[Blocker]` → `[Should]` → `[Nit]` → `[Pass]`, in that fixed order, never chronologically or interleaved with prose. One line each, with a `file:line` and the proposed fix inline:
   213	   ```
   214	   [Blocker] auth.py:42 — token isn't validated before use → Proposed fix: check `token.valid` before the call.
   215	   [Should] evidence.py:88 — magic number, extract a constant.
   216	   ```
   217	4. **Skip step 3 entirely** for 0–2 trivial findings, or a clean `Approved` with nothing to report — plain prose is fine. Don't force a sorted list where there's nothing to sort (same threshold `linear` uses for its own numbered-step format).
   218	
   219	This doesn't change what goes *in* the log — the log still uses the turn block formats above, verdict semantics are unchanged, and the Reviewer's `Approved`/`Changes requested`/`Blocked` distinction still governs whether the relay is open or closed. This section only governs how you *talk about* that log to the human.
   220	
   221	## What success looks like
   222	
   223	The human's entire role collapses to two actions: *"start a relay"* and *"your turn."* No text shuttled between windows, no extra notes outside the relay thread, no lost context — just one dated, git-diffable Markdown file holding the full review thread and every decision, ending cleanly on **Approved** or a clear escalation.
   224	
   225	---
   226	
   227	## Appendix — relay thread template
   228	
   229	Write this verbatim to `relay-system/<date>/<slug>.md` when starting a relay, filling the `<…>` fields. Newest turns append at the **bottom**, above the marker; the header and ground rules stay pinned at the top.
   230	
   231	The **▶ TAKE YOUR TURN** block is embedded in the template so a non-Claude agent (Codex, Gemini) that never loaded this skill can act correctly **from the file alone** — the operator's whole job stays a one-line nudge ("take your turn on `<file>`"), never a pasted wall of instructions. This base skill stays **partially manual** (a human nudges each turn); automating the nudge itself is the job of the `xyz`/relay-automation add-on, not this portable skill.
   232	
   233	```markdown
   234	# RELAY · <TITLE>
   235	<!--
   236	  Single source of truth for this two-agent relay.
   237	  Read this ENTIRE file before doing anything. Act only on your turn.
   238	-->
   239	
   240	NEXT: Producer
   241	STATUS: Open
   242	ROUND: 1 / 5
   243	
   244	## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
   245	The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
   246	1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
   247	2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
   248	3. **Do your role's work** on the artifact named in Setup (read the real files / the latest `git show <last commit>` diff; cite `file:line`):
   249	   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; you only append findings here. **Before you set `Approved`, re-read the artifact file itself** (not this log) and confirm every prior `Implemented` fix is actually present and complete — any that is missing or partial → set `Changes requested` with a `[Blocker] claimed-implemented-but-absent @ file:line` instead. For a doc artifact this file check is the only backstop there is.
   250	   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change, then add new work. **Before you flip `NEXT`, re-read the artifact and confirm each `Implemented → @ file:line` actually landed in the file** — cite the line as it appears in your commit diff. A claim you can't point to in the file is not done.
   251	4. **Append ONE block** at the very bottom, directly **above** the marker line (`<!-- ↓↓↓ NEXT TURN ... -->`). Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**`; a Producer block carries `**Decisions on proposals:**` + `**Did:**` + `**Re-review this:**` + `**Commit:**`. (Need the exact shape? Mirror the most recent block of the other role above.)
   252	5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`); the Producer bumps `ROUND` when opening a new cycle.
   253	6. **Commit only the files you touched** (artifact + this log): `git commit -m "relay(<slug>): <your-label> r<N>"`, then put the short hash in your block's `Commit:` line and `git commit --amend --no-edit`. Push if the team shares a remote.
   254	7. **Stop.** Tell the operator your one-line result (e.g. "Changes requested, 1 Blocker — Producer's turn").
   255	
   256	## Setup
   257	- Artifact under review: <PATH or PR URL>
   258	- Definition of Done: <ONE LINE — the bar the Reviewer checks against>
   259	- Producer: <name/agent>   ·   Reviewer: <name/agent>
   260	- Handoff: manual nudge   <!-- options: "manual nudge" · "hands-free poll (all-Claude)" · "cli-driven (agy)" · "cli-driven (codex)" — see skill -->
   261	- Started: <YYYY-MM-DD>
   262	
   263	## Ground rules
   264	1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents may be different tools (e.g. Claude and Codex) and never share memory.
   265	2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
   266	3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
   267	4. Stay tight. Requests and findings are bullets, not essays.
   268	5. **The Reviewer never edits the artifact.** It proposes graded findings, each with a concrete suggested fix where possible. The Producer (the original author), with the operator, decides each proposal and implements the approved ones — logging a disposition (Implemented / Modified / Declined + reason) for every one.
   269	6. Grade every finding:  `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional · `[Pass]` checked and sound (records what was verified, not assumed). Answer the Producer's "Re-review this" questions in an `Answers:` block.
   270	7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — so to get proposals actioned in-thread the Reviewer sets `Changes requested`, not `Approved`; a `[Nit]` left on an `Approved` verdict is the author's discretion, handled out-of-band. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
   271	8. End your turn by committing it: `relay(<slug>): <role> r<N>`, then fill the hash into your `Commit:` line — so the other agent can `git diff` exactly what changed. If your turn touched no tracked files (comments-only, or this log is gitignored), write `Commit: none (comments only)`.
   272	9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system, not a lock. Never start a turn while the other window may still be editing, and never flip `NEXT` with uncommitted changes left in the tree — commit or stash first, so the next agent never inherits half-finished state.
   273	10. **Evidence contract — state your proof every turn.** The Producer logs a one-line `Verification:` (what it ran / skipped / couldn't run); the Reviewer logs a verdict `Basis:` — `behaviorally proven` (ran/observed) or `textual only` (read, not run) — and classes any prior fix `textually fixed` vs `behaviorally proven`. An `Approved` can't silently mean "looked fine on read": if correctness rides on runtime behavior and nothing ran, `textual only` is the strongest honest verdict. Scales to the artifact — a pure doc answers `N/A — non-executable artifact`.
   274	11. **Reconcile claims against the file, not this log.** A disposition is a claim until the artifact proves it. The Producer, before flipping `NEXT`, re-reads the artifact (or `git show <its commit>`) and confirms each `Implemented → @ file:line` actually landed — citing the line as it appears in the commit diff. The Reviewer, before it may set `Approved`, re-reads the **artifact itself** and confirms every `Implemented` finding is present and complete; any missing or partial one flips the verdict to `Changes requested` with a `[Blocker] claimed-implemented-but-absent @ file:line`. For a non-executable artifact (design-spec / plan doc) this file check is the only backstop — so the closing approval is never granted on the log's word alone.
   275	
   276	## Roles
   277	- **Producer** — the only writer of the artifact: builds it, requests review, decides and implements proposals (with the operator), updates.
   278	- **Reviewer** — reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifact.
   279	
   280	---
   580	
   581	Run the shim test matching the worker you'll drive (both are first-class). Run these un-sandboxed —
   582	`mktemp`/network under the Bash sandbox can fail them for reasons unrelated to the code.
   583	
   584	## Relationship to the other skills
   585	
   586	- **`/relay`** — portable, dependency-free. Owns the thread template, turn block formats, evidence
   587	  contract, and guardrails. **Use it to scaffold the thread**; relay-xyz never redefines the protocol,
   588	  only runs it.
   589	- **`/xyz`** — concurrent, non-overlapping path-scoped lanes (parallel *builds*), also `tick`-backed.
   590	  A relay is sequential review (one writer, turn-based); `xyz` is parallel construction. Different
   591	  shapes.
   592	- **`consult.sh`** — `relay-automation/consult.sh` asks one question of Codex *and* agy in parallel,
   593	  captures both transcripts, leaves synthesis to you. Advisory-only, read-only, **not** a relay turn —
   594	  reach for it when you want a second opinion without a review loop.
   595	
   596	## Framing
   597	
   598	Open with a human sentence ("Driving a headless Codex or agy review of `<artifact>` — round cap 4…") and
   599	close with the result + exit code. The structured thread lives in the relay file; the operator gets a
   600	sentence and a verdict, not a wall of transcript.
   601	
   602	## Review Scope & Commensurate Complexity Standard
   603	
   604	Reviewers (Codex, agy, Claude, etc.) and authors must adhere to a strict standard of **commensurate complexity**:
   605	
   606	1. **Surgical, DRY, Safe, Secure, and Stable within Reason:** Reviews must evaluate correctness, safety, and invariants against the stated requirements without encouraging speculative over-engineering.
   607	2. **Commensurate Machinery & Tests:** Defensive handling, recovery mechanisms, and test footprints must remain strictly commensurate with the scale and role of the core code. An 80-line sync script or local tool must not become entangled with multi-layered enterprise fail-safes, distributed locks, journaled recovery, or bespoke fuzzing/scanning runtimes unless the operator explicitly specifies it.
   608	3. **Operational Envelope Grounding:** Reviewers must grade against the explicitly declared operational envelope (e.g. local developer CLI, single-repo task) rather than unrequested enterprise multi-tenant threat models.
   609	4. **Challenge Unwarranted Complexity:** Reviewers should actively challenge speculative abstractions, parallel subsystems, and overbuilding, acting as a filter *against* bloat rather than an engine of scope creep.
   610	
   611	## QA / Consult Template Formatting
   612	
   613	Since agents often scaffold relay threads manually (when the `/relay` slash command isn't used or available), it is critical to structure QA / consultation threads correctly. **Do not** write open-ended instructions like "QA this codebase against the requirements."
   614	
   615	Headless agents (Codex, agy, Aider) perform best when given **explicit questions and a defined operational envelope**. A proper QA thread must include:
   616	1. The goal, operational envelope, and files to read.
   617	2. Explicit statement of commensurate complexity and non-goals.
   618	3. A numbered list of concrete, specific questions to answer.
   619	4. Instructions on what the agent should output (e.g. file:line citations).
   620	
   621	**Example format:**
   622	```markdown
   623	---
   624	Goal: QA Phase 3 Implementation (Semantic Layer)
   625	Date: 2026-08-25
   626	NEXT: Reviewer
   627	STATUS: Open
   628	---
   629	
   630	# Context
   631	
   632	Adjudicate the implementation of Phase 3 Semantic Layer against its plan in PROJECT/2-WORKING/GH-1-firebase-ai-reports-plan.md.
   633	
   634	Operational Envelope: Local CLI tool. Tests and machinery must be commensurate with scope; do not demand unrequested enterprise multi-tenant fail-safes.
   635	
nl: relay-system/2026-09-17/gh673-final-qa.md: No such file or directory

exec
/bin/zsh -lc "nl -ba relay-automation/relay-turn-lib.sh | sed -n '810,960p'; nl -ba relay-automation/relay-turn-lib.sh | sed -n '1020,1160p'; nl -ba relay-automation/relay-turn-lib.sh | sed -n '1300,1440p'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-17340-oelbhd71
 succeeded in 0ms:
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
  1020	  f_rel="${f#"${root:+$root/}"}"
  1021	  if [[ "$f" == /* && -e "$f" ]]; then
  1022	    local _f_dir _f_phys _root_phys
  1023	    _f_dir="$(cd "$(dirname "$f")" 2>/dev/null && pwd -P)"
  1024	    _root_phys="$(cd "$root" 2>/dev/null && pwd -P)"
  1025	    if [[ -n "$_f_dir" && -n "$_root_phys" ]]; then
  1026	      _f_phys="$_f_dir/$(basename "$f")"
  1027	      [[ "$_f_phys" == "$_root_phys"/* ]] && f_rel="${_f_phys#"$_root_phys"/}"
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
  1059	rtl_before() {
  1060	  RTL_BEFORE_HEAD="$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)"
  1061	  # Snapshot the PRE-turn dirty set (raw -z porcelain fields) so enforcement touches only the
  1062	  # agent's OWN changes — never pre-existing ambient WIP in the host repo (field report MBP16 [1]).
  1063	  RTL_BEFORE=()
  1064	  local fld
  1065	  while IFS= read -r -d '' fld; do RTL_BEFORE+=("$fld"); done \
  1066	    < <(git -C "$RTL_ROOT" status --porcelain -z 2>/dev/null)
  1067	
  1068	  # GH-124 QW4: Early Rebase Drift Alert (Option A: zero-lock local tracking ref inspection)
  1069	  local drift_count
  1070	  drift_count="$(git -C "${RTL_ROOT:-.}" rev-list --count HEAD..refs/remotes/origin/development 2>/dev/null || echo 0)"
  1071	  if [ "${drift_count:-0}" -ge 3 ]; then
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
  1406	        _val_rf="$RTL_ROOT/$_val_rf"
  1407	      fi
  1408	    fi
  1409	    if [[ -f "$_val_rf" ]]; then
  1410	      # Structural relay-block validation applies to /relay threads (which structure rounds under ## Log / ## Setup).
  1411	      # Marathon-drive phase briefs use a distinct lifecycle managed by marathon-drive.
  1412	      if grep -qE '^[[:space:]]*##[[:space:]]*(Log|Setup)' "$_val_rf" 2>/dev/null; then
  1413	        local _val_bin
  1414	        _val_bin="$(rtl_validator_bin "$_val_tickroot")"
  1415	        [[ -z "$_val_bin" ]] && _val_bin="$(rtl_validator_bin "$RTL_ROOT")"
  1416	        if [[ -n "$_val_bin" && -x "$_val_bin" ]]; then
  1417	          local _val_out _val_rc=0
  1418	          _val_out="$("$_val_bin" "$_val_rf" 2>&1)" || _val_rc=$?
  1419	          if (( _val_rc != 0 )); then
  1420	            printf '%s-turn: relay block structural validation failed (exit %d):\n%s\n' "$RTL_TOOL" "$_val_rc" "$_val_out" >&2
  1421	            rtl_log_always "rtl_enforce: VALIDATION_FAILED exit=$_val_rc agent=$agent relay=$_val_rf"
  1422	            exit 8
  1423	          fi
  1424	          rtl_trace "rtl_enforce: relay block structural validation passed for $_val_rf"
  1425	        fi
  1426	      fi
  1427	    fi
  1428	  fi
  1429	  # (3) stage ONLY the allowlist; commit file-scoped; NO push.
  1430	  # Stage each allowlisted path INDEPENDENTLY (not one batched `git add -- a b c`): a single pathspec
  1431	  # that matches nothing — e.g. an allowlist entry the turn was permitted to create but didn't — makes
  1432	  # a batched `git add` abort and stage NOTHING, dropping even the paths that DID change. That is the
  1433	  # GH-29 cross-repo new-file gap: a builder that ADDS files under --target-root reported "no tracked
  1434	  # changes" and never committed, because a sibling non-matching entry aborted the batch (the modified
  1435	  # registry files were left `M` too — proof it was a whole-batch abort, not a new-file-only miss).
  1436	  # `-A` per path stages additions, modifications, AND deletions; `|| true` tolerates a non-matching
  1437	  # entry so the rest still stage. New untracked allowlisted files are added (they already passed the
  1438	  # exact-match enforcement above, so they ARE on-lane).
  1439	  local _ap
  1440	  for _ap in "${RTL_ALLOW[@]}"; do

exec
/bin/zsh -lc "rg --files | rg '(gh681|GH-681|gh673|GH-673|gh304|gh397|gh505|gh660|connectors.py|skills-army-hq/SKILL|WORKTREE-SAFETY|TESTS-RESULTS/README|HARNESS-MODELS)' ; nl -ba utils/py/express.py | sed -n '400,525p'; rg -n 'dry.run|check|diff|changed' utils/py/express.py | tail -40; nl -ba utils/py/rtl.py | sed -n '755,820p'; nl -ba test/gh304-vendored-relay-path.sh | sed -n '1,170p'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-17340-oelbhd71
 succeeded in 0ms:
src/flightdeck/connectors.py
HARNESS-MODELS-REGISTRY.md
HARNESS-MODELS-REGISTRY.generated.md
WORKTREE-SAFETY.md
TESTS-RESULTS/README.md
test/gh304-vendored-relay-path.sh
test/gh660-skill-drift.sh
test/gh505-relay-attest.sh
test/gh397-reviewer-turn-role.sh
relay-system/2026-09-08/gh505-implementation-qa.md
relay-system/2026-09-08/gh505-reviewer-integrity-plan-qa.md
relay-system/2026-09-17/gh681-relay-dod-vote-155755/gh681-relay-dod-vote.codex.md
relay-system/2026-09-17/gh681-relay-dod-vote-155755/gh681-relay-dod-vote.codex.NO-CITATION.txt
relay-system/2026-09-17/gh681-relay-dod-vote-155755/gh681-relay-dod-vote.agy.PROVENANCE.txt
relay-system/2026-09-17/gh681-relay-dod-vote-155755/gh681-relay-dod-vote.PROMPT.txt
relay-system/2026-09-17/gh681-relay-dod-vote-155755/gh681-relay-dod-vote.agy.md
relay-system/2026-09-17/gh681-relay-dod-vote-155755/gh681-relay-dod-vote.codex.PROVENANCE.txt
relay-system/2026-09-17/gh681-plan-qa-163853/gh681-plan-qa.PROMPT.txt
skills/skills-army-hq/SKILL.md
PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md
   400	    root = args.root
   401	
   402	    if not os.path.isdir(os.path.join(root, ".git")):
   403	        die("not a git repo: %s" % root)
   404	
   405	    branch = git(root, "branch", "--show-current").stdout.strip()
   406	    if branch in ("development", "main", ""):
   407	        refuse(root, "task-branch",
   408	               "express runs from a task branch cut off origin/development (SOP §4), "
   409	               "not from %r" % (branch or "(detached)"), issue=args.issue)
   410	
   411	    origin_dev = git(root, "rev-parse", "origin/development", check=False)
   412	    if origin_dev.returncode != 0:
   413	        refuse(root, "task-clone", "origin/development not found — clone from the GitHub remote", issue=args.issue)
   414	    is_ancestor = git(root, "merge-base", "--is-ancestor", "origin/development", "HEAD", check=False)
   415	    if is_ancestor.returncode != 0:
   416	        refuse(root, "task-clone",
   417	               "task branch is not based on origin/development — rebase onto origin/development",
   418	               issue=args.issue)
   419	    commit_count_res = git(root, "rev-list", "--count", "origin/development..HEAD", check=False)
   420	    commit_count = int(commit_count_res.stdout.strip() or "0") if commit_count_res.returncode == 0 else 0
   421	    if commit_count > 2:
   422	        refuse(root, "too-many-commits",
   423	               "the task branch carries %d commits ahead of origin/development (> 2 allowed); "
   424	               "express lands small hotfixes with <= 2 local commits — route to normal PR lane" % commit_count,
   425	               issue=args.issue)
   426	
   427	    # Gate wiring is proven, not assumed (PR #270 review finding 3): hooks do
   428	    # not travel with a clone. Express itself bypasses the hook on its own pushes
   429	    # (XYZ_SKIP_PREPUSH=1, lane design); this check keeps the clone's ordinary
   430	    # pushes gated so the lane cannot be used from an ungated clone.
   431	    wired, detail = gate_check(root)
   432	    if not wired:
   433	        refuse(root, "gate-unwired",
   434	               "`bash githooks/install.sh --check` did not prove the canonical gate stub; "
   435	               "run `bash githooks/install.sh` first (GH-549: wiring is per clone): %s" % detail,
   436	               issue=args.issue)
   437	
   438	    paths = change_paths(root)
   439	    if not paths:
   440	        refuse(root, "empty", "no changes present — nothing to express", issue=args.issue)
   441	
   442	    for p in paths:
   443	        if p in DRIVER_LEDGER and p not in expect_driver:
   444	            refuse(root, "ledger-hand-edit",
   445	                   "%s is a releases-ledger artifact — never hand-edited (verbs only); only "
   446	                   "the driver's own ledger phase may carry it" % p, issue=args.issue)
   447	        if p in DRIVER_GENERATED and p not in expect_driver:
   448	            refuse(root, "driver-output-hand-edit",
   449	                   "%s is generated by releases/roadmap verbs; only the driver's own "
   450	                   "projection refresh may carry it" % p, issue=args.issue)
   451	
   452	    core = [p for p in paths if not is_doc_path(p) and p not in expect_driver]
   453	
   454	    # Step 2 — hard refusals. Frozen twins, kernel surfaces, containment.
   455	    for p in core:
   456	        if p in FROZEN_TWINS:
   457	            refuse(root, "frozen-twin",
   458	                   "%s is a frozen Bash twin (GH-308) — the trailer flow "
   459	                   "needs human judgment, not an express lane" % p, issue=args.issue)
   460	        if p == SHARED_RUNTIME:
   461	            refuse(root, "shared-runtime",
   462	                   "%s is the shared Bash runtime dependency (not a twin, AGENTS.md) — "
   463	                   "too load-bearing for an express lane" % p, issue=args.issue)
   464	        if p.endswith(".sh") and (p.startswith("utils/") or p.startswith("relay-automation/")):
   465	            refuse(root, "no-new-bash",
   466	                   "%s — new/edited .sh under utils/ or relay-automation/ is rejected by the "
   467	                   "GH-551 guard; express will not carry it" % p, issue=args.issue)
   468	        for surface in KERNEL_SURFACES:
   469	            if p == surface or p.startswith(surface):
   470	                refuse(root, "kernel-surface",
   471	                       "%s is a coordination-kernel / containment surface (AGENTS: at least "
   472	                       "Costly) — express lands risk-bounded work only" % p, issue=args.issue)
   473	        if p.startswith("scratch/") or p.startswith("temp/") or p.endswith((".bak", ".orig", ".rej")):
   474	            refuse(root, "scratch", "%s is scratch/editor output — commit-worthy paths only" % p, issue=args.issue)
   475	
   476	    # Step 1 — bounds. Docs never count; code+test do.
   477	    if len(core) > args.max_files:
   478	        refuse(root, "too-many-files",
   479	               "%d core files > bound %d — route to the normal PR lane" % (len(core), args.max_files),
   480	               issue=args.issue)
   481	    ins = insertions(root, paths, expect_driver)
   482	    if ins > args.max_insertions:
   483	        refuse(root, "too-large",
   484	               "%d insertions > bound %d — route to the normal PR lane" % (ins, args.max_insertions),
   485	               issue=args.issue)
   486	    non_test = [p for p in core if not p.startswith("test/")]
   487	    tops = {p.split("/")[0] for p in non_test}
   488	    if len(tops) > 1:
   489	        allow_multi = getattr(args, "allow_multi_subsystem", False)
   490	        micro_diff = (len(core) <= 2 and ins <= 30)
   491	        if not allow_multi and not micro_diff:
   492	            refuse(root, "multi-subsystem",
   493	                   "core paths span %s — express is single-subsystem by contract "
   494	                   "(pass --allow-multi-subsystem or keep <= 30 insertions across <= 2 files)" % ", ".join(sorted(tops)),
   495	                   issue=args.issue)
   496	
   497	    # Step 3 — the issue must exist and be OPEN (closed => maybe already landed).
   498	    iv = gh(["issue", "view", str(args.issue), "-R", args.repo, "--json", "state,title"], check=False)
   499	    if iv.returncode != 0:
   500	        refuse(root, "issue-missing", "gh cannot resolve issue #%s in %s" % (args.issue, args.repo), issue=args.issue)
   501	    meta = json.loads(iv.stdout)
   502	    if meta.get("state") != "OPEN":
   503	        refuse(root, "issue-closed",
   504	               "issue #%s is %s — the work may already be landed; run the preflight "
   505	               "already-landed probes before re-doing it" % (args.issue, meta.get("state")), issue=args.issue)
   506	
   507	    # Step 4 — the fix must carry its regression suite, registered in validate.sh.
   508	    suite = normalize_suite(args.suite)
   509	    if not os.path.isfile(os.path.join(root, suite)):
   510	        refuse(root, "suite-missing", "%s does not exist — a hotfix without its regression suite is a claim, not a fix" % suite, issue=args.issue)
   511	    validate = os.path.join(root, "validate.sh")
   512	    with open(validate, encoding="utf-8", errors="replace") as f:
   513	        vbody = f.read()
   514	    if ('"%s"' % os.path.basename(suite)) not in vbody:
   515	        refuse(root, "suite-unregistered",
   516	               "%s is not registered in validate.sh TESTS — an unregistered suite never runs in the gate" % suite,
   517	               issue=args.issue)
   518	
   519	    print("express-check%s: PASS" % (" [dry-run]" if getattr(args, "dry_run", False) else ""))
   520	    print("  issue   : #%s %s" % (args.issue, meta.get("title", "")))
   521	    print("  files   : %d core, %d insertions (bounds %d/%d)" % (len(core), ins, args.max_files, args.max_insertions))
   522	    print("  suite   : %s (registered)" % suite)
   523	    print("  changes : %s" % ", ".join(paths))
   524	    return dict(issue=args.issue, title=meta.get("title", ""), paths=paths, suite=suite,
   525	                insertions=ins, branch=branch)
699:    state = cmd_check(args, expect_driver=expect)  # re-qualify at landing time
705:    if getattr(args, "dry_run", False):
706:        print("express-land [dry-run]: would run suite %s" % suite)
714:        wired, detail = gate_check(root)
717:                   "the suite changed or disabled the canonical pre-push gate: %s" % detail,
722:    # diff plus the driver's own projections, then stage ONLY those paths.
730:               "qualified paths or content changed after the suite ran (%s) — express stages "
734:    if getattr(args, "dry_run", False):
735:        print("express-land [dry-run]: PASS — would commit %s, push to origin/development, close issue #%d, and reconcile"
737:        return dict(sha="dry-run", release=args.release or "(active)")
753:        git(root, "checkout", "-q", "development")
755:        dirty = git(root, "status", "--porcelain=v1", check=False).stdout.strip()
759:        reached = git(root, "merge-base", "--is-ancestor", sha, "origin/development", check=False)
789:    # reachability checks (so no cleanliness guard ever sees it untracked) and from the
803:    iv = gh(["issue", "view", str(args.issue), "-R", args.repo, "--json", "state"], check=False)
905:    form: check / docs / ledger / land, each its own process) has no other way
931:        res = git(root, "rev-parse", "--verify", "%s^{commit}" % explicit_sha, check=False)
935:        reached = git(root, "merge-base", "--is-ancestor", sha, "origin/development", check=False)
938:        body = git(root, "log", "-1", "--format=%B", sha, check=False).stdout
944:    log_res = git(root, "log", "origin/development", "-n", "50", "--format=%H%x00%B%x00", check=False)
976:        res = git(root, "rev-parse", "--verify", "%s^{commit}" % ship_commit_sha_for_issue, check=False)
979:            reached = git(root, "merge-base", "--is-ancestor", s_sha, "origin/development", check=False)
981:                s_body = git(root, "log", "-1", "--format=%B", s_sha, check=False).stdout
990:def check_manifest_state(root, issue, rel):
1022:    cur_branch = git(root, "branch", "--show-current", check=False).stdout.strip()
1023:    dirty = git(root, "status", "--porcelain=v1", check=False).stdout.strip()
1032:    if getattr(args, "dry_run", False):
1033:        print("express-resume [dry-run]: would ensure issue #%d closed, reconcile commit %s, and persist/push" % (issue, sha[:12]))
1036:    # 3. Switch to clean development checkout if on another branch
1038:        git(root, "checkout", "-q", "development")
1040:        dirty_after = git(root, "status", "--porcelain=v1", check=False).stdout.strip()
1056:    iv = gh(["issue", "view", str(issue), "-R", args.repo, "--json", "state"], check=False)
1065:        mstate = check_manifest_state(root, issue, rel)
1091:    cmd_check(args)  # first qualification: the operator's diff, nothing else
1094:    if getattr(args, "dry_run", False):
1119:        p.add_argument("--dry-run", action="store_true", default=False,
1122:    p = sub.add_parser("check", help="steps 0-3: tree, bounds, forbidden surfaces, issue, suite")
1124:    p.set_defaults(fn=cmd_check)
1151:    p.add_argument("--dry-run", action="store_true", default=False, help="preview operations without modifying files or git state")
1163:    if getattr(args, "suite", None) is None and args.cmd in ("check", "land", "run"):
   755	else
   756	  rtl_init {shlex.quote(self.root)} {shlex.quote(self.relay_file)} {shlex.quote(normalized_allow_csv(self.allow_paths))} >/dev/null 2>&1
   757	fi
   758	
   759	{cmd_str}
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
     1	#!/usr/bin/env bash
     2	# test/gh304-vendored-relay-path.sh — GH-304 regression.
     3	#
     4	# Primary bug: driving a relay whose file lives in a SUBDIRECTORY of the true git repo root (the
     5	# same-repo vendored `.xyz/` shape) used to embed a CWD-relative path in the turn-taker's prompt and
     6	# fail to seed the file into the isolation worktree, so a headless turn-taker (Codex) whose worktree
     7	# roots at the git toplevel could not find the relay file — a 100% failure. relay-drive.sh now
     8	# absolutizes the relay path before exporting it, and rtl_turn_prompt derives the repo-root-relative
     9	# EDIT path robustly, so the embedded path and the seeded path are the true repo-root-relative one.
    10	#
    11	# Secondary bug: when the relay file is gitignored, a turn that DID append findings produces the same
    12	# empty commit-set as a genuine no-op, and both used to print byte-identical "no tracked changes
    13	# (token-only move?)". rtl_enforce now prints a distinct, accurate message for the gitignored case.
    14	#
    15	# Unit-tests rtl_turn_prompt / rtl_worktree_begin / rtl_enforce directly (same pattern as
    16	# relay-file-seeding-visibility.sh and relay-commit-pathspec.sh) — no model stub needed.
    17	source "$(dirname "$0")/_setup.sh" gh304-vendored-relay-path
    18	LIB="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-turn-lib.sh"
    19	# shellcheck source=relay-automation/relay-turn-lib.sh
    20	source "$LIB"
    21	
    22	# Ensure $A has a checked-out branch at a real commit, independent of the ambient git
    23	# init.defaultBranch (some hosts default the bare remote's HEAD to master while _setup.sh pushes main,
    24	# leaving the clone with an unborn HEAD that `git worktree add HEAD` can't check out). Defensive only —
    25	# does not affect what the test proves.
    26	git -C "$A" rev-parse --verify -q HEAD >/dev/null 2>&1 \
    27	  || git -C "$A" checkout -q -B main origin/main >/dev/null 2>&1 \
    28	  || git -C "$A" commit -q --allow-empty -m "gh304 base" >/dev/null 2>&1 || true
    29	
    30	# --- Case 1 (primary): relay file in a SUBDIR of the git root, passed ABSOLUTE (as relay-drive does) ---
    31	# `.xyz/` is a plain subdir (no .git of its own) — the exact vendored-.xyz shape. RTL_ROOT resolves to
    32	# the git toplevel ($A), so the correct repo-root-relative path is `.xyz/relay-system/…`.
    33	REL=".xyz/relay-system/2026-07-24/gh304.md"
    34	RELAY_SUB="$A/$REL"
    35	mkdir -p "$(dirname "$RELAY_SUB")"
    36	printf 'STATUS: In progress\nNEXT: Producer\nGH304 CONTENT %s\n' "$$" >"$RELAY_SUB"
    37	
    38	rtl_init "$A" "$RELAY_SUB" ""
    39	
    40	# Env-independent check of the normalization that DRIVES seeding: the allowlist entry (and thus the
    41	# rtl_worktree_begin `-e "$RTL_ROOT/$a"` seed check) must be the true repo-root-relative path.
    42	if [ "${RTL_ALLOW[0]:-}" = "$REL" ]; then
    43	  pass "rtl_init normalizes the allowlist entry to the repo-root-relative path ($REL)"
    44	else
    45	  fail "rtl_init allowlist entry is '${RTL_ALLOW[0]:-}', expected '$REL'"
    46	fi
    47	
    48	prompt="$(rtl_turn_prompt codex "$RELAY_SUB" RELAY-TURN "" other)"
    49	if grep -qF "Read $REL " <<<"$prompt"; then
    50	  pass "turn prompt embeds the repo-root-relative relay path ($REL)"
    51	else
    52	  fail "turn prompt did not embed the repo-root-relative relay path; got: $(grep -oE 'Read [^ ]+' <<<"$prompt" | head -1)"
    53	fi
    54	# The absolute path must NOT leak into the prompt — an absolute EDIT path invites a write straight into
    55	# RTL_ROOT, bypassing the worktree (the exact hazard rtl_turn_prompt's repo-root-relative rule avoids).
    56	if grep -qF "Read $A/" <<<"$prompt"; then
    57	  fail "turn prompt leaked an ABSOLUTE relay path"
    58	else
    59	  pass "turn prompt did not leak an absolute relay path"
    60	fi
    61	# And it must not degrade to a bare basename (unresolvable from the worktree root).
    62	if grep -qE "Read gh304\.md( |$)" <<<"$prompt"; then
    63	  fail "turn prompt embedded a bare basename (loses the .xyz/ prefix)"
    64	else
    65	  pass "turn prompt kept the full repo-root-relative prefix"
    66	fi
    67	
    68	wt="$(rtl_worktree_begin)"; rc=$?
    69	if [ "$rc" -eq 0 ] && [ -n "$wt" ] && [ -f "$wt/$REL" ]; then
    70	  pass "worktree seeds the relay file at the repo-root-relative path"
    71	  if grep -q "GH304 CONTENT $$" "$wt/$REL" 2>/dev/null; then
    72	    pass "seeded worktree copy has the CURRENT (uncommitted) content"
    73	  else
    74	    fail "seeded worktree copy has stale content"
    75	  fi
    76	else
    77	  fail "worktree did not seed the relay file at $REL (rc=$rc, wt=$wt)"
    78	fi
    79	[ -n "$wt" ] && { git -C "$A" worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"; git -C "$A" worktree prune >/dev/null 2>&1; }
    80	
    81	# --- Case 2 (secondary): a gitignored relay file gets a distinct, accurate empty-commit message ---
    82	printf '.tick/\nrelay-system/\n' >"$A/.gitignore"
    83	git -C "$A" add .gitignore >/dev/null 2>&1
    84	git -C "$A" commit -q -m "seed gitignore" >/dev/null 2>&1
    85	LOG="$WORK/enforce.log"; : >"$LOG"
    86	
    87	IGN="relay-system/2026-07-24/gh304-ignored.md"
    88	mkdir -p "$(dirname "$A/$IGN")"
    89	printf 'STATUS: In progress\nNEXT: Producer\n' >"$A/$IGN"
    90	rtl_init "$A" "$A/$IGN" ""
    91	rtl_before
    92	printf '\n### Round 1 · Reviewer\nreal graded finding appended here %s\n' "$$" >>"$A/$IGN"   # real work
    93	out="$( rtl_enforce "T-IGN" "codex" "$LOG" "codex" 2>/dev/null )"; rc=$?
    94	[ "$rc" -eq 0 ] && pass "gitignored relay turn still exits 0" || fail "gitignored case expected exit 0, got $rc"
    95	if grep -q "gitignored" <<<"$out" && grep -q "NOT git-tracked" <<<"$out"; then
    96	  pass "gitignored relay file gets the distinct 'gitignored / not git-tracked' message"
    97	else
    98	  fail "gitignored relay file did not get the distinct message; got: $out"
    99	fi
   100	if grep -q "no tracked changes (token-only move?)" <<<"$out"; then
   101	  fail "gitignored relay file still prints the misleading 'no tracked changes (token-only move?)' message"
   102	else
   103	  pass "gitignored relay file does NOT print the misleading token-only-move message"
   104	fi
   105	
   106	# --- Case 3 (control): a TRACKED, unchanged relay file (a genuine no-op) keeps the original message ---
   107	printf 'STATUS: Open\n# tracked relay\n' >"$A/tracked-relay.md"
   108	git -C "$A" add tracked-relay.md >/dev/null 2>&1
   109	git -C "$A" commit -q -m "seed tracked relay" >/dev/null 2>&1
   110	rtl_init "$A" "$A/tracked-relay.md" ""
   111	rtl_before
   112	# deliberately no edit → a true token-only move
   113	out3="$( rtl_enforce "T-NOOP" "codex" "$LOG" "codex" 2>/dev/null )"; rc3=$?
   114	[ "$rc3" -eq 0 ] && pass "control: tracked no-op turn exits 0" || fail "control expected exit 0, got $rc3"
   115	if grep -q "no tracked changes (token-only move?)" <<<"$out3"; then
   116	  pass "control: a genuine tracked no-op still reports 'no tracked changes (token-only move?)'"
   117	else
   118	  fail "control: expected the original token-only-move message for a tracked no-op; got: $out3"
   119	fi
   120	
   121	echo "  $TEST_NAME: $PASS pass, $FAIL fail"
   122	exit 0

codex
The shared prompt still tells reviewers to “verify ONLY with the specific test for the file(s) you changed,” which conflicts with the proposed probe allowance. I also found that the planned express check would run before there are any changes to classify, so it cannot produce the expected refusal receipt.

exec
/bin/zsh -lc "nl -ba src/flightdeck/connectors.py | sed -n '1,200p'; nl -ba test/gh397-reviewer-turn-role.sh | sed -n '1,160p'; rg -n 'case G|Case G|STATUS: Approved|prompt|probe|scratch' test/gh505-relay-attest.sh; nl -ba test/gh660-skill-drift.sh | sed -n '1,140p'; nl -ba relay-automation/README.md | sed -n '1,70p'; nl -ba .gitignore | sed -n '1,65p'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-17340-oelbhd71
 succeeded in 0ms:
     1	from __future__ import annotations
     2	
     3	import json
     4	import re
     5	import sqlite3
     6	import time
     7	from datetime import datetime
     8	from pathlib import Path
     9	from typing import Any, Callable
    10	from urllib.parse import urlsplit
    11	
    12	from .contract import (
    13	    MAX_RECORDS,
    14	    ConnectorConfig,
    15	    bounded_text,
    16	    deadline_guard,
    17	    empty_batch,
    18	    parse_time,
    19	    repo_key,
    20	    repo_name,
    21	    safe_path,
    22	    utc_now,
    23	)
    24	
    25	Connector = Callable[[ConnectorConfig, float], dict[str, Any]]
    26	
    27	
    28	def canonical_github_key(stored_name: Any, html_url: Any = None) -> str | None:
    29	    """Prefer GitHub's item URL when a cached repo slug predates a rename."""
    30	    if isinstance(html_url, str):
    31	        parts = [part for part in urlsplit(html_url).path.split("/") if part]
    32	        if len(parts) >= 2:
    33	            key = repo_key("/".join(parts[:2]))
    34	            if key:
    35	                return key
    36	    return repo_key(stored_name)
    37	
    38	
    39	def work_references(text: str, repo: str | None = None) -> dict[str, list[int]]:
    40	    """Keep issue and PR intent separate; qualified URLs must match this repo."""
    41	    refs: dict[str, list[int]] = {"issues": [], "prs": []}
    42	    pattern = r"https?://[^\s<>]+|(?:(?P<kind>PR|pull\s+request)\s*#?|(GH-|#|\bissue\s+))(?P<number>\d+)\b"
    43	    for match in re.finditer(pattern, text, re.I):
    44	        if match.group("number"):
    45	            kind = "prs" if match.group("kind") else "issues"
    46	            number = int(match.group("number"))
    47	        else:
    48	            try:
    49	                url = urlsplit(match.group().rstrip(').,]'))
    50	            except ValueError:
    51	                continue
    52	            parts = url.path.strip('/').split('/')
    53	            if url.hostname != "github.com" or len(parts) < 4 or parts[2] not in {"issues", "pull"} or not parts[3].isdigit():
    54	                continue
    55	            target = repo_key('/'.join(parts[:2]))
    56	            if repo and target != repo and not (repo.startswith('local/') and target.rsplit('/', 1)[-1] == repo.rsplit('/', 1)[-1]):
    57	                continue
    58	            kind, number = ("prs" if parts[2] == "pull" else "issues"), int(parts[3])
    59	        if number > 0 and number not in refs[kind]:
    60	            refs[kind].append(number)
    61	    return refs
    62	
    63	
    64	def issue_numbers(text: str, repo: str | None = None) -> list[int]:
    65	    return work_references(text, repo)["issues"]
    66	
    67	
    68	def _available(batch: dict[str, Any], observed: str | None, coverage: str = "partial") -> dict[str, Any]:
    69	    batch["source"].update({"availability": "ok", "coverage": coverage, "observed_through": observed, "error": None})
    70	    return batch
    71	
    72	
    73	def read_clio(config: ConnectorConfig, deadline: float) -> dict[str, Any]:
    74	    caps = ("agent_intent", "repo_attention")
    75	    batch = empty_batch("clio", caps, "unavailable")
    76	    if not config.clio_jsonl:
    77	        return batch
    78	    path = safe_path(config.clio_jsonl)
    79	    newest: str | None = None
    80	    repos: dict[str, dict[str, Any]] = {}
    81	    lanes: dict[tuple[str, str], dict[str, Any]] = {}
    82	    rows = bounded_text(path).splitlines()[-MAX_RECORDS:]
    83	    parsed = []
    84	    for line in rows:
    85	        deadline_guard(deadline)
    86	        try:
    87	            row = json.loads(line)
    88	        except json.JSONDecodeError:
    89	            continue
    90	        if isinstance(row, dict) and parse_time(row.get("timestamp")):
    91	            parsed.append(row)
    92	    for row in sorted(parsed, key=lambda row: datetime.fromisoformat(parse_time(row["timestamp"]).replace("Z", "+00:00")).timestamp()):
    93	        deadline_guard(deadline)
    94	        occurred = parse_time(row.get("timestamp"))
    95	        key = repo_key(row.get("repo"))
    96	        prompt_full = " ".join(str(row.get("prompt") or "").split())
    97	        prompt = prompt_full[:240]
    98	        if not occurred or not key or not prompt_full:
    99	            continue
   100	        newest = max(newest or occurred, occurred)
   101	        repos.setdefault(key, {"id": key, "name": repo_name(key), "aliases": [str(row.get("repo"))], "source_refs": ["clio"]})
   102	        refs = work_references(prompt_full, key)
   103	        referenced_issues = refs["issues"]
   104	        session = str(row.get("session_id") or row.get("id") or occurred)
   105	        lane_key = (key, session)
   106	        prior = lanes.get(lane_key, {})
   107	        if prior:
   108	            latest = datetime.fromisoformat(occurred.replace("Z", "+00:00")).timestamp()
   109	            previous = datetime.fromisoformat(prior["last_prompt_at"].replace("Z", "+00:00")).timestamp()
   110	            if (latest - previous) > 7200:
   111	                prior = {}
   112	        has_reference = bool(referenced_issues or refs["prs"])
   113	        lane = {
   114	            "id": f"clio:{key}:{session}",
   115	            "repo_id": key, "issue": referenced_issues[0] if referenced_issues else None,
   116	            "issues": referenced_issues if has_reference else prior.get("issues", []),
   117	            "prs": refs["prs"] if has_reference else prior.get("prs", []),
   118	            "agent": row.get("agent") or prior.get("agent") or "Agent", "session_id": row.get("session_id"),
   119	            "branch": row.get("branch") or prior.get("branch"), "device": row.get("machine") or prior.get("device"),
   120	            "task": prompt, "last_prompt_at": occurred, "last_progress_at": None,
   121	            "confidence": "inferred", "source_ref": "clio",
   122	            "issue_context_at": occurred if has_reference else prior.get("issue_context_at"),
   123	        }
   124	        lane["issue"] = next(iter(lane["issues"]), None)
   125	        lanes[lane_key] = lane
   126	    batch["repos"] = list(repos.values())
   127	    batch["lanes"] = list(lanes.values())
   128	    return _available(batch, newest, "partial")
   129	
   130	
   131	def read_git_pulse(config: ConnectorConfig, deadline: float) -> dict[str, Any]:
   132	    caps = ("commits", "device_coverage")
   133	    batch = empty_batch("git_pulse", caps, "unavailable")
   134	    if not config.git_pulse_dir:
   135	        return batch
   136	    root = safe_path(config.git_pulse_dir)
   137	    files = sorted(root.glob("pulse-*.md"), key=lambda p: p.stat().st_mtime, reverse=True)[:50]
   138	    repos: dict[str, dict[str, Any]] = {}
   139	    newest: str | None = None
   140	    for path in files:
   141	        path = safe_path(path, root)
   142	        for line in bounded_text(path).splitlines()[-MAX_RECORDS:]:
   143	            deadline_guard(deadline)
   144	            fields = line.strip().strip("`|").split("\t")
   145	            if len(fields) != 6 or not fields[0].isdigit():
   146	                continue
   147	            epoch, timestamp, raw_repo, branch, sha, subject = fields
   148	            occurred = parse_time(timestamp) or parse_time(epoch)
   149	            key = repo_key(raw_repo)
   150	            if not occurred or not key:
   151	                continue
   152	            newest = max(newest or occurred, occurred)
   153	            repos.setdefault(key, {"id": key, "name": repo_name(key), "aliases": [raw_repo], "source_refs": ["git_pulse"]})
   154	            batch["events"].append({
   155	                "id": f"pulse:{path.name}:{epoch}:{sha}", "repo_id": key,
   156	                "kind": "commit", "summary": subject[:240], "issues": issue_numbers(subject, key), "occurred_at": occurred,
   157	                "observed_at": datetime_from_mtime(path), "sha": sha, "branch": branch,
   158	                "source_ref": "git_pulse", "confidence": "attested",
   159	            })
   160	    batch["repos"] = list(repos.values())
   161	    return _available(batch, newest, "partial")
   162	
   163	
   164	def datetime_from_mtime(path: Path) -> str:
   165	    from datetime import datetime, timezone
   166	    return datetime.fromtimestamp(path.stat().st_mtime, timezone.utc).isoformat().replace("+00:00", "Z")
   167	
   168	
   169	def _sqlite_rows(conn: sqlite3.Connection, sql: str, params: tuple[Any, ...] = ()) -> list[dict[str, Any]]:
   170	    conn.row_factory = sqlite3.Row
   171	    return [dict(row) for row in conn.execute(sql, params).fetchall()]
   172	
   173	
   174	def read_rebalance(config: ConnectorConfig, deadline: float) -> dict[str, Any]:
   175	    caps = ("projects", "issues", "pull_requests", "checks", "next_actions", "commits")
   176	    batch = empty_batch("rebalance", caps, "unavailable")
   177	    if not config.rebalance_db:
   178	        return batch
   179	    path = safe_path(config.rebalance_db)
   180	    conn = sqlite3.connect(f"file:{path}?mode=ro", uri=True, timeout=1)
   181	    try:
   182	        conn.execute("PRAGMA query_only=ON")
   183	        deadline_guard(deadline)
   184	        repos: dict[str, dict[str, Any]] = {}
   185	        project_keys: dict[str, list[str]] = {}
   186	        for row in _sqlite_rows(conn, "SELECT name, status, summary, repos_json FROM project_registry LIMIT 100"):
   187	            try:
   188	                aliases = json.loads(row.get("repos_json") or "[]")
   189	            except json.JSONDecodeError:
   190	                aliases = []
   191	            for alias in aliases if isinstance(aliases, list) else []:
   192	                raw = alias.get("repo") if isinstance(alias, dict) else alias
   193	                key = repo_key(raw)
   194	                if key:
   195	                    repos.setdefault(key, {"id": key, "name": row["name"] or repo_name(key), "summary": row.get("summary"), "aliases": [str(raw)], "source_refs": ["rebalance"]})
   196	                    project_keys.setdefault(str(row["name"]), []).append(key)
   197	        action_rows = _sqlite_rows(conn, "SELECT computed_at,payload_json FROM ranked_next_actions ORDER BY computed_at DESC LIMIT 1")
   198	        if action_rows:
   199	            try:
   200	                ranked = json.loads(action_rows[0]["payload_json"]).get("ranked", [])
     1	#!/usr/bin/env bash
     2	# test/gh397-reviewer-turn-role.sh — GH-397 regression.
     3	# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh397-reviewer-turn-role.sh; pre-fix revision: relay-turn-lib.sh before d4999cd, where rtl_is_reviewer_turn read only the agent-maintained NEXT: prose; pre-fix result: case 3 FAILED — a builder that never flipped NEXT: left the reviewer running with the builder's write scope; post-fix result: 11/0, role derived from the marathon-drive directive with the NEXT: line kept only as the fallback"}
     4	#
     5	# `NEXT:` is the relay's state variable, and two drivers wrote two incompatible VALUE DOMAINS into
     6	# it. relay-drive writes a ROLE (Producer|Reviewer); marathon-drive writes an AGENT ID
     7	# (claude|codex|agy). rtl_is_reviewer_turn — the shared reader, used by BOTH lanes — tested for the
     8	# literal word "Reviewer", so in a marathon it always returned false.
     9	#
    10	# The consequence was not cosmetic. rtl_init uses that answer to SCOPE THE ALLOWLIST: on a reviewer
    11	# turn it drops ALLOW_PATHS so the reviewer can only append to the relay file. Returning false meant
    12	# every marathon reviewer turn kept write authority over the artifact it was reviewing AND received
    13	# the builder's "Edit ONLY <relay> and: <artifact>" prompt — the exact boundary an over-eager agy
    14	# reviewer crossed on 2026-06-20 when it edited validate.sh.
    15	#
    16	# The fix does NOT ask the acting model to rewrite NEXT: itself. test/agy-turn.sh (S2) already locks
    17	# in that agents skip that flip and nothing catches it; a containment boundary hung on that honor
    18	# system fails OPEN. Instead the role is DERIVED from two things no agent authors: the machine-
    19	# readable role directive marathon-drive renders into the relay file, and RELAY_AGENT, which
    20	# relay-drive exports from the tick token. Case 3 below is the whole point of the design.
    21	source "$(dirname "$0")/_setup.sh" gh397-reviewer-turn-role
    22	LIB="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-turn-lib.sh"
    23	# shellcheck source=relay-automation/relay-turn-lib.sh
    24	source "$LIB"
    25	
    26	mk_marathon_relay() {  # <path> <next-line>
    27	  printf '# Marathon Phase p1\nSTATUS: Open\nNEXT: %s\n\n<!-- marathon-drive: task=MARATHON-p1 builder=codex reviewer=agy round-cap=6 -->\n\nbody\n' \
    28	    "$2" > "$1"
    29	}
    30	
    31	M="$WORK/marathon-relay.md"
    32	
    33	# --- Case 1: the reported bug. Marathon relay, reviewer acting. -------------------------------
    34	mk_marathon_relay "$M" "agy (Reviewer)"
    35	rtl_is_reviewer_turn "$M" agy \
    36	  && pass "marathon reviewer turn is recognized as a REVIEWER turn" \
    37	  || fail "marathon reviewer turn still reads as a builder turn — GH-397 is back"
    38	
    39	# --- Case 2: the builder must NOT be scoped as a reviewer (it legitimately builds) ------------
    40	mk_marathon_relay "$M" "codex (Builder)"
    41	rtl_is_reviewer_turn "$M" codex \
    42	  && fail "marathon BUILDER turn was scoped as a reviewer — its artifact edits would be reverted" \
    43	  || pass "marathon builder turn is not a reviewer turn"
    44	
    45	# --- Case 3: THE POINT. The builder forgot to flip NEXT; the reviewer is still scoped. --------
    46	# NEXT: still names the BUILDER — the exact drift test/agy-turn.sh S2 proves is uncaught. Under a
    47	# prompt-instruction fix this returns false and the reviewer silently regains artifact write
    48	# authority. Deriving the role from the directive + tick-token agent makes the stale pointer
    49	# irrelevant: the boundary no longer depends on anything a model remembered to do.
    50	mk_marathon_relay "$M" "codex (Builder)"
    51	rtl_is_reviewer_turn "$M" agy \
    52	  && pass "reviewer stays scoped even when the builder never flipped NEXT (fails CLOSED)" \
    53	  || fail "a forgotten NEXT: flip silently unscoped the reviewer — the boundary is back on the honor system"
    54	
    55	# --- Case 4/5: plain /relay threads carry no directive and must behave exactly as before ------
    56	P="$WORK/plain-relay.md"
    57	printf 'STATUS: Open\nNEXT: Reviewer\n\nbody\n' > "$P"
    58	rtl_is_reviewer_turn "$P" agy \
    59	  && pass "plain relay thread with NEXT: Reviewer is still a reviewer turn" \
    60	  || fail "regressed the plain /relay Producer|Reviewer path"
    61	
    62	printf 'STATUS: Open\nNEXT: Producer\n\nbody\n' > "$P"
    63	rtl_is_reviewer_turn "$P" agy \
    64	  && fail "plain relay thread with NEXT: Producer read as a reviewer turn" \
    65	  || pass "plain relay thread with NEXT: Producer is not a reviewer turn"
    66	
    67	# --- Case 6: no agent known (a hand-run turn) falls back to the NEXT: header ------------------
    68	mk_marathon_relay "$M" "agy (Reviewer)"
    69	rtl_is_reviewer_turn "$M" "" \
    70	  && pass "with no acting agent, the NEXT: header still decides (hand-run turns keep working)" \
    71	  || fail "an agentless call stopped honoring the NEXT: header"
    72	
    73	# --- Case 7: a self-review lane (builder == reviewer) carries no role signal — fall through ---
    74	printf '# Marathon Phase p1\nSTATUS: Open\nNEXT: agy (Reviewer)\n\n<!-- marathon-drive: task=MARATHON-p1 builder=agy reviewer=agy round-cap=6 -->\n\nbody\n' > "$M"
    75	rtl_is_reviewer_turn "$M" agy \
    76	  && pass "builder==reviewer lane falls back to the NEXT: header rather than guessing" \
    77	  || fail "builder==reviewer lane resolved a role it cannot know"
    78	
    79	# --- Case 8: the user-visible symptom — the reviewer's PROMPT and allowlist -------------------
    80	# Case 1 proves the predicate. This proves the two things that predicate actually controls, which is
    81	# what the issue reported: contradictory scope statements in one context window.
    82	mkdir -p "$A/phases/p1"
    83	MP="$A/phases/p1/RELAY.md"
    84	mk_marathon_relay "$MP" "codex (Builder)"    # stale pointer again — worst case, on purpose
    85	
    86	prompt="$(rtl_turn_prompt agy "$MP" MARATHON-p1 "src/thing.py" codex)"
    87	printf '%s' "$prompt" | grep -Fq "You are the REVIEWER this turn" \
    88	  && pass "reviewer prompt carries the REVIEWER scope note" \
    89	  || fail "reviewer prompt has no REVIEWER note — the safety text is still never delivered"
    90	printf '%s' "$prompt" | grep -Fq "src/thing.py" \
    91	  && fail "reviewer prompt still lists the artifact as editable — the contradiction GH-397 reported" \
    92	  || pass "reviewer prompt drops the artifact from the editable set"
    93	
    94	RELAY_AGENT=agy rtl_init "$A" "$MP" "src/thing.py"
    95	[ "${RTL_WAS_REVIEWER_TURN:-0}" = "1" ] \
    96	  && pass "rtl_init records the reviewer turn (allowlist scoped to the relay file only)" \
    97	  || fail "rtl_init did not scope the reviewer turn — artifact edits would not be reverted"
    98	[ "${#RTL_ALLOW[@]}" -eq 1 ] \
    99	  && pass "reviewer allowlist holds the relay file and nothing else" \
   100	  || fail "reviewer allowlist still carries ${#RTL_ALLOW[@]} entries: ${RTL_ALLOW[*]}"
   101	
   102	exit 0
8:#   A   a builder-role turn that writes STATUS: Approved is reverted, committed as reverted, and
21:#   G   the builder prompt no longer says "set STATUS: Approved"; the reviewer prompt does
32:# ---- fixture harness: a copy of the shipped scripts, so .relay-scratch and locks land in $WORK ----
63:    perl -pi -e 's/^STATUS:.*/STATUS: Approved/' "\$f"
68:    perl -pi -e 's/^STATUS:.*/STATUS: Approved/' "\$f"
80:    perl -pi -e 's/^STATUS:.*/STATUS: Approved/; s/^NEXT:.*/NEXT: done/' "\$f"
84:    perl -pi -e 's/^STATUS:.*/STATUS: Approved/' "\$f"
88:    perl -pi -e 's/^STATUS:.*/STATUS: Approved/' "\$f" ;;
91:    perl -pi -e 's/^STATUS:.*/STATUS: Approved/' "\$f"
95:    perl -pi -e 's/^STATUS:.*/STATUS: Approved/; s/^NEXT:.*/NEXT: done/' "\$f"
119:reset_repo(){ git -C "$A" reset -q --hard "$SEED" >/dev/null 2>&1; git -C "$A" clean -qfd >/dev/null 2>&1; rm -rf "$MAIN/.relay-scratch"; rm -f "$(git -C "$A" rev-parse --absolute-git-dir)"/relay-attest/*.json 2>/dev/null; }
128:reason(){ cat "$MAIN/.relay-scratch/escalation-reason" 2>/dev/null; }
133:# --- A: builder-role turn forges STATUS: Approved -------------------------------------------------
247:perl -pi -e 's/^STATUS:.*/STATUS: Approved/' "$A/relay.md"; git -C "$A" commit -qam "pre-approved" >/dev/null
286:perl -pi -e 's/^STATUS:.*/STATUS: Approved/' "$A/relay.md"
309:open(rf, "wb").write(orig.replace(b"STATUS: Approved", b"STATUS: Closed", 1)); assert not ok(), "STATUS edit accepted"
330:rf = os.path.join(r, "src", "review[1].md"); open(rf, "w").write("STATUS: Approved\nbody\n"); open(os.path.join(r, "src", "service.py"), "w").write("v1\n")
340:# --- F / G: containment reads the driver; prompt ----------------------------------------------
362:prompt_of(){ ( export RELAY_DRIVER_LOCKED=1 RELAY_ROLE="$1"; bash -c "source '$RTL' >/dev/null 2>&1; rtl_init '$WORK/fg' '$RF' 'art.md' >/dev/null 2>&1; rtl_turn_prompt rev '$RF' T-G art.md peer" ); }
363:BP="$(prompt_of builder)"; RP="$(prompt_of reviewer)"
364:[ -n "$BP" ] && [ -n "$RP" ] && pass "G: both prompts render non-empty" || fail "G: empty prompt"
365:! grep -q 'STATUS: Approved' <<<"$BP" && pass "G: builder prompt does not invite STATUS: Approved" || fail "G: builder prompt still says Approved"
366:grep -q 'set STATUS: Approved' <<<"$RP" && pass "G: reviewer prompt carries the approval instruction" || fail "G: reviewer prompt lacks it"
395:open(rf, "a").write("\n### Round 1 · Reviewer · rev\nok\n"); txt = open(rf).read(); open(rf, "w").write(txt.replace("STATUS: Open", "STATUS: Approved", 1))
458:  perl -pi -e 's/^STATUS:.*/STATUS: Approved/' "$A/relay.md"; git -C "$A" commit -qam "pre-approved" >/dev/null
     1	#!/usr/bin/env bash
     2	# GH-660: skill_drift_check names vendored SKILL.md copies that diverge from
     3	# canonical skills/, stays silent on identical vendors, and treats
     4	# collection-only extras as informational — with a mutation proof.
     5	set -euo pipefail
     6	
     7	ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
     8	export PYTHONPATH="$ROOT/utils/py:${PYTHONPATH:-}"
     9	
    10	FIX="$(mktemp -d)"; trap 'rm -rf "$FIX"' EXIT
    11	mkdir -p "$FIX/canonical/skills/alpha" "$FIX/canonical/skills/beta" \
    12	         "$FIX/collection/alpha" "$FIX/collection/beta" "$FIX/collection/gamma"
    13	printf 'canonical alpha\n' > "$FIX/canonical/skills/alpha/SKILL.md"
    14	printf 'canonical beta\n'  > "$FIX/canonical/skills/beta/SKILL.md"
    15	printf 'canonical alpha\n' > "$FIX/collection/alpha/SKILL.md"   # identical vendor
    16	printf 'stale beta\n'      > "$FIX/collection/beta/SKILL.md"    # DRIFTED
    17	printf 'foreign\n'         > "$FIX/collection/gamma/SKILL.md"   # unrecognized extra
    18	
    19	pass=0; fail=0
    20	assert() {  # <desc> <expected-rc> <out-substring...>
    21	  local desc="$1" want_rc="$2" needle="$3" rc=0 out
    22	  out="$(python3 "$ROOT/utils/py/skill_drift_check.py" \
    23	    --canonical "$FIX/canonical" --collection "$FIX/collection")" && rc=0 || rc=$?
    24	  if [ "$rc" -eq "$want_rc" ] && grep -q "$needle" <<<"$out"; then
    25	    pass=$((pass+1)); echo "  PASS: $desc"
    26	  else
    27	    fail=$((fail+1)); echo "  FAIL: $desc (rc=$rc want=$want_rc; needle='$needle' missing)"
    28	    echo "$out" | sed 's/^/    | /'
    29	  fi
    30	}
    31	
    32	# 1. drifted vendor named, exit 1, clean vendor not in the drift list.
    33	assert "drifted vendor named with canonical path" 1 "DRIFTED  beta:"
    34	# 2. collection-only extra is informational, never a failure cause.
    35	assert "unrecognized extra reported informationally" 1 "UNRECOGNIZED  gamma:"
    36	# 3. identical vendor present and counted ok.
    37	assert "identical vendor counted ok" 1 "1 ok"
    38	
    39	# 4. clean tree (remove the drifted vendor) → exit 0.
    40	rm "$FIX/collection/beta/SKILL.md"
    41	out="$(python3 "$ROOT/utils/py/skill_drift_check.py" \
    42	  --canonical "$FIX/canonical" --collection "$FIX/collection")" && rc=0 || rc=$?
    43	[ "$rc" -eq 0 ] && grep -q "0 drifted" <<<"$out" \
    44	  && pass=$((pass+1)) && echo "  PASS: no drifted vendors -> exit 0" \
    45	  || { fail=$((fail+1)); echo "  FAIL: clean tree must exit 0 (got $rc): $out"; }
    46	
    47	# 5. Mutation proof: a check that cannot fail is not a check — mutate canonical
    48	#    beta and the SAME vendor must now be flagged (fixture proven load-bearing).
    49	printf 'canonical beta v2\n' > "$FIX/canonical/skills/beta/SKILL.md"
    50	printf 'stale beta\n' > "$FIX/collection/beta/SKILL.md"   # restore the vendor test 4 removed
    51	out="$(python3 "$ROOT/utils/py/skill_drift_check.py" \
    52	  --canonical "$FIX/canonical" --collection "$FIX/collection")" && rc=0 || rc=$?
    53	[ "$rc" -eq 1 ] && grep -q "DRIFTED  beta:" <<<"$out" \
    54	  && pass=$((pass+1)) && echo "  PASS: mutation proof — stale vendor re-flags after canonical moves" \
    55	  || { fail=$((fail+1)); echo "  FAIL: mutation proof (rc=$rc): $out"; }
    56	
    57	# 6. --json carries the same verdict machine-readably. Capture first: the
    58	# checker exits 1 on drift and pipefail would swallow the parser's verdict.
    59	json_out="$(python3 "$ROOT/utils/py/skill_drift_check.py" --canonical "$FIX/canonical" \
    60	  --collection "$FIX/collection" --json)" || true
    61	printf '%s' "$json_out" | python3 -c '
    62	import json, sys
    63	r = json.load(sys.stdin)
    64	assert [e["skill"] for e in r["drifted"]] == ["beta"], r
    65	assert r["unrecognized"][0]["skill"] == "gamma", r
    66	' && pass=$((pass+1)) && echo "  PASS: --json verdict matches" \
    67	  || { fail=$((fail+1)); echo "  FAIL: --json verdict mismatch"; }
    68	
    69	echo "gh660-skill-drift: $pass pass, $fail fail"
    70	[ "$fail" -eq 0 ]
     1	# relay-automation
     2	
     3	A tick-backed automation layer for the manual `/relay` review loop and `xyz`
     4	build swarms. Built in phases on top of `tick` (see
     5	[PROPOSAL-AUTOMATION.md](../PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md)).
     6	
     7	**Execution contract: default live-window flow** — the default operator path is
     8	still the poll-driven, live-window flow: a Claude window under `/loop`, or a
     9	human one-line nudge when the turn belongs to a non-Claude window. Headless
    10	turn-takers now exist for Claude, Codex, agy, and Pi (`claude-turn.sh`, `codex-turn.sh`,
    11	`agy-turn.sh`, `pi-turn.sh`). Claude setup is covered in [subscription mode](#claude-subscription-mode).
    12	`relay-loop.sh --background --cross-model-cmd <shim>` can now auto-fire one of
    13	those shims on `DECISION: nudge-cross-model`; without that wrapper-only flag,
    14	the loop still degrades to the existing manual nudge. For the current headless path, see
    15	[Set up Codex, agy, and Pi below](#set-up-codex-agy-and-pi-headless-bring-up), plus
    16	[CROSSMODEL-OPTIONA-PLAN.md](CROSSMODEL-OPTIONA-PLAN.md).
    17	
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
    36	## Adding a new consult advisor (GH-178 A1)
    37	
    38	The default Python implementation dispatches advisors in `utils/py/consult.py`. Add the
    39	vendor invocation there, reuse `guarded_with_timeout` and the existing result aggregation,
    40	and register a regression suite in `validate.sh`. Account-specific preflight and result
    41	parsing belong in a helper shared with that vendor's relay adapter. The Bash fallback is
    42	frozen; do not extend its dispatch table. Relay adapters retain the shared `RelayTurnLib`
    43	contract for claims, scoped writes, cleanup, and handoff.
    44	
    45	## Claude subscription mode
    46	
    47	Use an installed **Claude Code CLI** signed in with your own Claude.ai subscription:
    48	
    49	```bash
    50	claude auth login
    51	claude auth status
    52	export CLAUDE_AUTH_MODE=subscription
    53	# If Claude is outside PATH, set CLAUDE_BIN to its executable's absolute path.
    54	relay-automation/consult.sh --models claude \
    55	  --prompt 'Read README.md and identify one issue with a file:line citation.'
    56	```
    57	
    58	This opt-in mode uses native `claude -p` and verifies `claude auth status` in the same
    59	directory and environment as the request. It requires an authenticated first-party
    60	Pro, Max, Team, or Enterprise Claude.ai account. API-key/helper authentication,
    61	API/provider environment overrides, failed probes, and unrecognized account shapes
    62	stop the Claude lane with an actionable error. Credentials remain managed by Claude Code;
    63	XYZ does not extract OAuth tokens, run a proxy, or retry through an API billing route.
    64	Use a CLI version that supports JSON `auth status` and `--restricted` for consult
    65	(validated with 2.1.270); unsupported versions fail rather than bypass the checks.
    66	
    67	`CLAUDE_AUTH_MODE=inherit` (the default) skips subscription validation. Relay retains
    68	the CLI's existing authentication/settings. Claude consult uses native `--restricted`
    69	in both modes: file tools stay within its temporary checkout, configured MCP tools
    70	are excluded, and user/project/local settings are ignored. The account preflight uses
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

exec
/bin/zsh -lc "rg -n 'sqlite3.connect|mkdir|open\\(|write|CREATE|commit\\(' utils/py/releases_app.py | head -45; nl -ba utils/py/codex-turn.py | sed -n '1,65p'; rg -n 'turn_prompt|PROMPT|env|cwd|TMPDIR|subprocess|aider.*message' utils/py/aider-turn.py; rg -n 'gate-evidence|provenance' TESTS-RESULTS/README.md; nl -ba AGENTS.md | sed -n '7,20p'; rg -n 'disposable|guard.*path|temp/|Costly|provenance' AGENTS.md | head -20; nl -ba utils/py/express.py | sed -n '120,160p'; nl -ba test/gh505-relay-attest.sh | sed -n '145,168p'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-17340-oelbhd71
 succeeded in 0ms:
8:Authority split (PRD "Decisions" 1): the DB is authoritative for reads/writes at runtime; the
13:protocol in perform_write()/recover_from_journal().
16:The SQLite DB (releases.db) is authoritative for reads and writes at runtime; releases.sql is
23:tracked, generated artifact that conflicted on every concurrent write, one staged output from every
24:write transaction, and one crash-recovery surface. The three CLI readers (`list`, `show`, `next`)
33:  releases-app.lock              the repo-scoped writer lock
35:                                 the DB/dump/digest/generation contract, so a refused writer
37:  releases-app-journal.json      intent journal; exists only mid-write (crash-recovery input)
49:Readers (no lock, no write, safe to run anywhere): `list` (one line per release), `show` (one
54:4 writer-lock refusal; 70 injected crash.
76:# GH-491: one vocabulary for CLI writes and the dashboard's ledgerSections.
90:EXIT_REFUSED = 3      # a rule refused the write; stderr names the rule
117:# dead end that only the schema knew about — `manifest ship` writes it. Both `shipped` and `cut` are
144:# GH-525: some repos write a literal placeholder in RELEASES.md for a release that has not shipped
156:# The settings keys an operator may write with `releases settings set`. Deliberately a
157:# deny-by-default allowlist: `generation` belongs to the writer protocol and `repo_slug` is the
361:    """Append-only contention evidence, OUTSIDE the DB (r4 review finding: a refused writer
362:    inserting into the committed DB would itself be an unlocked write, able to tear the very trio
368:        with open(audit_path, "a", encoding="utf-8") as fh:
369:            fh.write(line)
375:    """Repo-scoped writer lock (PRD Git story 1). Every acquisition attempt is logged to the
389:            self.fh = open(self.lock_path, "a+", encoding="utf-8")
400:                    refuse("writer-lock",
401:                           "another releases-app writer holds %s; refusal recorded in the "
408:            self.fh.write("%s %s %s\n" % (now_iso(), session_id(), os.getpid()))
434:    # isolation_level=None: transactions are BEGIN/COMMIT'd explicitly by perform_write, so the
436:    conn = sqlite3.connect(db_path, isolation_level=None)
486:CREATE TABLE schema_migrations (
491:CREATE TABLE settings (            -- per-repo DB, so per-repo enforcement mode lives here
496:CREATE TABLE repos (
503:CREATE TABLE issue_refs (          -- normalized issue reference: real URL XOR placeholder
514:CREATE TABLE marathons (
523:CREATE TABLE releases (
544:CREATE TABLE manifest_items (
553:CREATE TABLE manifest_state_events (   -- append-only re-scope trail (review finding: the old
554:  id INTEGER PRIMARY KEY,              -- single overwriteable state_changed cell lost history)
562:CREATE TRIGGER mse_no_update BEFORE UPDATE ON manifest_state_events
564:CREATE TRIGGER mse_no_delete BEFORE DELETE ON manifest_state_events
568:-- transaction; a direct writer that skips the event is caught by the digest chain below, not
571:CREATE TABLE doc_lines (               -- document-level verbatim preservation (r2: the 86-line
579:CREATE TABLE legacy_lines (            -- lossless import: unmapped/continuation lines, verbatim
588:CREATE TABLE grandfather_entries (     -- r3: referenced throughout but previously never defined
598:CREATE TABLE op_receipts (             -- append-only CLI operation log (append-only via the same
613:CREATE TRIGGER op_no_update BEFORE UPDATE ON op_receipts
615:CREATE TRIGGER op_no_delete BEFORE DELETE ON op_receipts
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
1:#!/usr/bin/env python3
6:import subprocess
19:        r = subprocess.run([aider_bin, "--help"], capture_output=True, text=True)
29:        r = subprocess.run(["git", "-C", root, "hash-object", "--", path], capture_output=True, text=True)
36:            r = subprocess.run(["cksum"], stdin=fh, capture_output=True, text=True)
46:        print("Required environment variables: RELAY_AGENT, RELAY_FILE, RELAY_TASK")
49:    xyz_root = os.environ.get("XYZ_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
54:    root = resolve_turn_root(os.environ.get("AIDER_TURN_ROOT"), xyz_root)
55:    aider_bin = os.environ.get("AIDER_BIN", "aider")
58:    # the OpenRouter default, byte-identical to the pre-GH-147 behavior. Same env-var contract Phase 1
60:    aider_openai_api_base = os.environ.get("AIDER_OPENAI_API_BASE", "")
62:        aider_model = os.environ.get("AIDER_MODEL", "openai/agents-a1")
64:        aider_model = os.environ.get("AIDER_MODEL", "openrouter/anthropic/claude-sonnet-5")
66:    me = os.environ.get("RELAY_AGENT", "")
67:    f = os.environ.get("RELAY_FILE", "")
68:    t = os.environ.get("RELAY_TASK", "RELAY-TURN")
69:    aider_agent = os.environ.get("AIDER_AGENT", "")
84:    aider_env = os.environ.copy()
86:        # Keep the key out of ps-visible argv. Aider/LiteLLM reads OPENAI_API_KEY from its child env.
87:        aider_env["OPENAI_API_KEY"] = os.environ.get("AIDER_OPENAI_API_KEY", "dummy")
89:    elif not os.environ.get("OPENROUTER_API_KEY"):
93:    allow_paths = os.environ.get("ALLOW_PATHS", "")
94:    peer = os.environ.get("RELAY_PEER", "")
98:    prompt = rtl.turn_prompt(me, t, peer)
99:    tick_repo_root = os.environ.get("TICK_REPO_ROOT", root)
123:                diff_res = subprocess.run(diff_cmd, capture_output=True, text=True)
136:    aider_log = os.environ.get("AIDER_LOG") or rtl_default_log(root, "aider-turn", t)
137:    aider_aux_dir = os.environ.get("AIDER_AUX_DIR", os.path.join(tempfile.gettempdir(), f"aider-aux-{os.getpid()}"))
142:    turn_timeout = int(os.environ.get("RELAY_TURN_TIMEOUT_S", 900))
157:    xflags = os.environ.get("AIDER_FLAGS", "")
168:    run_cwd = root
170:    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
173:            run_cwd = wt
175:            os.environ["TICK_REPO_ROOT"] = tick_repo_root
180:    cmd = [aider_bin] + aider_args + ["--message", prompt]
185:            subprocess.run(cmd, cwd=run_cwd, env=aider_env, timeout=turn_timeout, stdout=log_f, stderr=subprocess.STDOUT, check=True)
186:    except subprocess.TimeoutExpired:
188:    except subprocess.CalledProcessError as e:
252:                    r = subprocess.run(["git", "-C", root, "ls-files", "--error-unmatch", ap], capture_output=True)
254:                        subprocess.run(["git", "-C", root, "checkout", "HEAD", "--", ap], capture_output=True)
276:            gateway=os.environ.get(
280:            reasoning_effort=os.environ.get("AIDER_REASONING_EFFORT", "high"),
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
16:  run mutation-heavy gates only in a separate disposable full clone.
78:Consequential changes get a read on the shared scale: **Easy / Costly / One-way door**, with one line
79:of why. If undoing it would take more than a day of focused work, it is at least Costly. Costly
100:An uncommitted `provenance.jsonl` is not proof (GH-430). Any run cited as evidence in an issue, PR,
101:ROADMAP entry, or decision record must have its `provenance.jsonl` committed in the same PR — a path
125:If a change is Costly, One-way door, or assumption-heavy, record the bet in `CHANGELOG.md` per
222:- **Scratch and temporary files go in `temp/`, never the repo root.** `/temp/` is already gitignored
299:  install, and the resolution ladder and agent-facing invocation flow + guardrails are in [skills/hq/SKILL.md](skills/hq/SKILL.md). Write paths preview by default; `fire` never drives the harness.
301:  broader than they look. Treat them as at least Costly until proven otherwise.
304:  `isolation: "worktree"` so a runaway destructive command shreds a disposable checkout, not the main
   120	    except OSError:
   121	        pass
   122	
   123	
   124	
   125	def git(root, *args, check=True, env=None):
   126	    merged_env = os.environ.copy()
   127	    if env:
   128	        merged_env.update(env)
   129	    r = subprocess.run(["git", "-C", root] + list(args), capture_output=True, text=True, env=merged_env)
   130	    if check and r.returncode != 0:
   131	        die("git %s failed: %s" % (" ".join(args[:2]), r.stderr.strip()))
   132	    return r
   133	
   134	
   135	
   136	def gh(args, check=True):
   137	    r = subprocess.run(["gh"] + list(args), capture_output=True, text=True)
   138	    if check and r.returncode != 0:
   139	        die("gh %s failed: %s" % (args[0], r.stderr.strip()))
   140	    return r
   141	
   142	
   143	def releases_app(root):
   144	    app = os.path.join(root, "utils", "py", "releases_app.py")
   145	    if not os.path.isfile(app):
   146	        die("releases_app.py not found under %s — express requires a canonical-repo layout" % root)
   147	    return app
   148	
   149	
   150	def run_releases(root, *args, check=True):
   151	    r = subprocess.run([sys.executable, releases_app(root)] + list(args),
   152	                       cwd=root, capture_output=True, text=True)
   153	    if check and r.returncode != 0:
   154	        die("releases %s failed: %s" % (args[0], (r.stderr or r.stdout).strip()))
   155	    return r
   156	
   157	
   158	# ── provenance receipt (GH-592) ───────────────────────────────────────────
   159	# The one producer of express evidence. The receipt's `commit` is the identity
   160	# `wave_reconcile.py --gate` reads (check_provenance_receipts matches it against
   145	# --- A2: the same forgery on a FAILED turn (codex exits non-zero; GH-432 still commits the turn) ---
   146	#         keeps the shim's own exit code and is still reverted — never attested.
   147	reset_repo; seed_to T-A2 bld
   148	run_driver "$DRIVER" T-A2 failafter --reviewer rev --builder bld; rc=$?
   149	[ "$rc" -eq 5 ] && pass "A2: failed turn keeps the shim's exit 5 (not 4)" || fail "A2: expected 5, got $rc: $(tail -3 "$WORK/out-T-A2")"
   150	[ "$(reason)" = forged-terminal ] && pass "A2: reason still names the forgery" || fail "A2: reason=$(reason)"
   151	grep -q '^STATUS: Open' <<<"$(git -C "$A" show HEAD:relay.md)" && pass "A2: forged STATUS reverted in HEAD on the failure path" || fail "A2: HEAD still forged"
   152	[ ! -f "$(record_path T-A2)" ] && pass "A2: no record" || fail "A2: record written on a failed turn"
   153	
   154	# --- A3: a FAILED reviewer turn that approved is reverted, never attested (shim's exit preserved) --
   155	reset_repo; seed_to T-A3 rev
   156	run_driver "$DRIVER" T-A3 failafter --reviewer rev --builder bld; rc=$?
   157	[ "$rc" -eq 5 ] && pass "A3: failed reviewer turn keeps the shim's exit 5" || fail "A3: expected 5, got $rc: $(grep -v GH-370 "$WORK/out-T-A3" | tail -3)"
   158	[ "$(reason)" = failed-turn-terminal ] && pass "A3: reason is failed-turn-terminal" || fail "A3: reason=$(reason)"
   159	grep -q '^STATUS: Open' <<<"$(git -C "$A" show HEAD:relay.md)" && pass "A3: the failed turn's Approved reverted in HEAD" || fail "A3: HEAD still Approved"
   160	[ ! -f "$(record_path T-A3)" ] && ! grep -q 'Attestation · relay-drive' "$A/relay.md" && pass "A3: no trailer, no record" || fail "A3: attestation published for a failed turn"
   161	
   162	# --- B: reviewer-role approval is attested -------------------------------------------------------
   163	reset_repo; seed_to T-B rev
   164	HEAD_BEFORE="$(git -C "$A" rev-parse HEAD)"
   165	run_driver "$DRIVER" T-B approve --reviewer rev --builder bld; rc=$?
   166	[ "$rc" -eq 0 ] && pass "B: reviewer approval → driver exits 0" || fail "B: expected 0, got $rc: $(tail -5 "$WORK/out-T-B")"
   167	grep -q '^### Attestation · relay-drive' "$A/relay.md" && pass "B: attestation trailer appended" || fail "B: no trailer"
   168	grep -q "^reviewed-head: $HEAD_BEFORE" "$A/relay.md" && pass "B: reviewed-head = HEAD before dispatch" || fail "B: reviewed-head wrong: $(grep '^reviewed-head' "$A/relay.md")"

exec
/bin/zsh -lc "rg -n '"'^_rtl_sig|PYTHONDONTWRITEBYTECODE|TMPDIR|readonly|mode=ro|_connect'"' relay-automation/relay-turn-lib.sh utils/py/releases_app.py | head -45; nl -ba relay-automation/relay-turn-lib.sh | sed -n '655,718p'; nl -ba utils/py/aider-turn.py | sed -n '94,115p'; nl -ba utils/py/aider-turn.py | sed -n '145,187p'; rg -n 'G:|G —|prompt contains|set STATUS' test/gh505-relay-attest.sh; nl -ba TESTS-RESULTS/README.md | sed -n '1,100p'; rg -n 'landed|merge|intake.py|source|update ' skills/skills-army-hq/SKILL.md | tail -25" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-17340-oelbhd71
 succeeded in 0ms:
utils/py/releases_app.py:1595:def _dispatch_work_connectors(db_path, at):
utils/py/releases_app.py:1606:        import work_connectors
utils/py/releases_app.py:1607:        return work_connectors.dispatch(db_path, at)
utils/py/releases_app.py:1719:        _dispatch_work_connectors(paths["db"], now)
utils/py/releases_app.py:5085:            _dispatch_work_connectors(paths["db"], now_iso())
utils/py/releases_app.py:5097:        import work_connectors
utils/py/releases_app.py:5098:        for name, cfg in sorted(work_connectors.load_connectors(warn=False).items()):
utils/py/releases_app.py:5150:        print("review-ready scan skipped: no repository identity (set work_connectors.<name>.repos)")
utils/py/releases_app.py:5285:        db_uri = "file:%s?mode=ro" % urllib.parse.quote(db_path, safe="/")
utils/py/releases_app.py:5419:        import work_connectors
utils/py/releases_app.py:5420:        report["enabled_connectors"] = sorted(work_connectors.load_connectors(warn=False))
utils/py/releases_app.py:5422:        report["enabled_connectors"] = []
utils/py/releases_app.py:5429:            ",".join(report["enabled_connectors"]) or "disabled"))
utils/py/releases_app.py:5451:    import work_connectors
utils/py/releases_app.py:5452:    conns = work_connectors.load_connectors()
utils/py/releases_app.py:5457:                   "connector %r is not enabled in work_connectors" % args.connector)
utils/py/releases_app.py:5471:    results = work_connectors.dispatch(paths["db"], now_iso(), connectors=conns,
utils/py/releases_app.py:6183:    conn = sqlite3.connect("file:%s?mode=ro" % db_path, uri=True)
relay-automation/relay-turn-lib.sh:204:# GH-388: the $TMPDIR fallbacks below are GONE, and this now REFUSES (exit 5) rather than silently
relay-automation/relay-turn-lib.sh:578:  # partial). Disk-quota belongs in a TMPDIR watchdog; spend ceilings are model-shim-specific.
relay-automation/relay-turn-lib.sh:707:_rtl_sig() {  # <path> — content signature of a file/dir, or "ABSENT". Used to detect what the turn
relay-automation/relay-turn-lib.sh:727:  # GH-236: in /tmp-rooted environments $TMPDIR can resolve INSIDE the working root, which drops the
relay-automation/relay-turn-lib.sh:729:  # a failure that then surfaces mislabeled as a turn timeout. Default to $TMPDIR so behaviour is
relay-automation/relay-turn-lib.sh:730:  # unchanged everywhere else; ONLY when $TMPDIR lands inside RTL_ROOT, relocate the worktree root
relay-automation/relay-turn-lib.sh:731:  # under the repo's own git metadata dir (never part of the working tree, never under $TMPDIR) —
relay-automation/relay-turn-lib.sh:733:  wt_root="${TMPDIR:-/tmp}"
relay-automation/relay-turn-lib.sh:741:      rtl_trace "rtl_worktree_begin: RELOCATED worktree root off \$TMPDIR (inside RTL_ROOT) -> $wt_root (GH-236)"
relay-automation/relay-turn-lib.sh:1048:  # GH-91: name the scratch affordance at the point of use — prose in a phase brief ("use \$TMPDIR")
relay-automation/relay-turn-lib.sh:1138:  printf '%s-turn: SCRATCH RELOCATION (GH-113): untracked root-level %s moved to %s — turn NOT failed. Write scratch under $TMPDIR or .relay-scratch/ instead.\n' \
   655	  fields="$(python3 - "$path" <<'PYEOF'
   656	import datetime as dt
   657	import json
   658	import sys
   659	
   660	try:
   661	    with open(sys.argv[1]) as f:
   662	        data = json.load(f)
   663	    pid = int(data["pid"])
   664	    updated = dt.datetime.fromisoformat(str(data["updated_utc"]).replace("Z", "+00:00"))
   665	    age = max(0, int((dt.datetime.now(dt.timezone.utc) - updated).total_seconds()))
   666	    print(f"{pid}\t{age}")
   667	except Exception:
   668	    pass
   669	PYEOF
   670	)"
   671	  [[ "$fields" == *$'\t'* ]] || { printf 'finished'; return 1; }
   672	  pid="${fields%%$'\t'*}"; age="${fields#*$'\t'}"
   673	  case "$pid:$age" in *[!0-9:]*|:*) printf 'finished'; return 1 ;; esac
   674	  if kill -0 "$pid" 2>/dev/null; then
   675	    printf 'running'
   676	    return 0
   677	  fi
   678	  if [[ "$age" -gt "$stale_after" ]]; then
   679	    printf 'stale'
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
   711	  if [[ -f "$p" ]]; then
   712	    git hash-object -- "$p" 2>/dev/null || echo "ERR:$p"
   713	  elif [[ -d "$p" ]]; then
   714	    # Stable per-dir signature: hash each tracked-or-untracked file's content in sorted order.
   715	    ( cd "$p" 2>/dev/null && find . -type f -print0 2>/dev/null | LC_ALL=C sort -z \
   716	        | xargs -0 git hash-object 2>/dev/null ) | git hash-object --stdin 2>/dev/null || echo "ERR:$p"
   717	  else
   718	    echo "ABSENT"
    94	    peer = os.environ.get("RELAY_PEER", "")
    95	    
    96	    rtl = RelayTurnLib(root, xyz_root, f, allow_paths)
    97	    
    98	    prompt = rtl.turn_prompt(me, t, peer)
    99	    tick_repo_root = os.environ.get("TICK_REPO_ROOT", root)
   100	    drift_brief = rtl.drift_brief(me, tick_repo_root)
   101	    
   102	    if drift_brief:
   103	        prompt = drift_brief + "\n" + prompt
   104	        
   105	    prompt += "\n\nNOTE (Aider harness): do NOT run any tick commands — the harness has already claimed the token and will release/close it for you after your edit. Spend this turn ONLY editing the file(s) added to the chat: append your block to the relay file and set its STATUS, and edit the artifact(s) if this is a build turn."
   106	    if "qwen" in aider_model.lower():
   107	        prompt += "\n\nCRITICAL CONSTRAINT: Keep your internal reasoning extremely brief (under 50 words). Output your SEARCH/REPLACE blocks immediately."
   108	
   109	    claim_paths = claim_paths_for_turn(root, f, allow_paths)
   110	    rel_relay = claim_paths[0]
   111	    file_args = ["--file", rel_relay]
   112	    for path in claim_paths[1:]:
   113	        file_args.extend(["--file", path])
   114	    
   115	    read_args = []
   145	    if aider_supports_add_gitignore_files(aider_bin):
   146	        gitignore_args.append("--add-gitignore-files")
   147	
   148	    aider_args = [
   149	        "--model", aider_model, "--yes-always", "--no-auto-commits"
   150	    ] + aider_auth_args + gitignore_args + [
   151	        "--no-check-update", "--no-analytics", "--no-show-model-warnings", "--no-stream", "--map-tokens", "0",
   152	        "--chat-history-file", os.path.join(aider_aux_dir, "chat.history.md"),
   153	        "--input-history-file", os.path.join(aider_aux_dir, "input.history"),
   154	        "--llm-history-file", os.path.join(aider_aux_dir, "llm.history")
   155	    ] + file_args + read_args
   156	    
   157	    xflags = os.environ.get("AIDER_FLAGS", "")
   158	    if xflags:
   159	        aider_args.extend(shlex.split(xflags))
   160	        
   161	    # GH-251: signature the relay file BEFORE the turn so a review-only turn that produced a graded
   162	    # review in the transcript but landed NO relay-file append can be detected and salvaged after.
   163	    relay_presig = relay_sig(root, f)
   164	
   165	    rtl.before()
   166	
   167	    wt = ""
   168	    run_cwd = root
   169	    
   170	    if os.environ.get("RELAY_WORKTREE_ISOLATION", "0") == "1":
   171	        wt = rtl.worktree_begin()
   172	        if wt:
   173	            run_cwd = wt
   174	            print(f"aider-turn: worktree isolation ON ({wt})", file=sys.stderr)
   175	            os.environ["TICK_REPO_ROOT"] = tick_repo_root
   176	        else:
   177	            print("aider-turn: worktree isolation requested but `git worktree add` failed — failing turn", file=sys.stderr)
   178	            sys.exit(5)
   179	
   180	    cmd = [aider_bin] + aider_args + ["--message", prompt]
   181	    
   182	    bounded_rc = 0
   183	    try:
   184	        with open(aider_log, "w") as log_f:
   185	            subprocess.run(cmd, cwd=run_cwd, env=aider_env, timeout=turn_timeout, stdout=log_f, stderr=subprocess.STDOUT, check=True)
   186	    except subprocess.TimeoutExpired:
   187	        bounded_rc = 7
21:#   G   the builder prompt no longer says "set STATUS: Approved"; the reviewer prompt does
265:[ "$rc" -eq 4 ] && [ "$(reason)" = forged-terminal ] && grep -q 'WARNING — no --reviewer' "$WORK/out-T-E2" && pass "E2: no --reviewer → warned at startup; the approval is refused as forged (no reviewer can exist)" || fail "E2: rc=$rc reason=$(reason)"
340:# --- F / G: containment reads the driver; prompt ----------------------------------------------
364:[ -n "$BP" ] && [ -n "$RP" ] && pass "G: both prompts render non-empty" || fail "G: empty prompt"
365:! grep -q 'STATUS: Approved' <<<"$BP" && pass "G: builder prompt does not invite STATUS: Approved" || fail "G: builder prompt still says Approved"
366:grep -q 'set STATUS: Approved' <<<"$RP" && pass "G: reviewer prompt carries the approval instruction" || fail "G: reviewer prompt lacks it"
     1	# Test Results & Artifacts (`TESTS-RESULTS/`)
     2	
     3	This directory contains committed execution artifacts, benchmark datasets, and structured telemetry logs from autonomous testing campaigns (such as ATE variation runs, fuzzing loops, and harness evaluations).
     4	
     5	## Purpose
     6	
     7	Per repo rail **Rule 6 ("Verified beats plausible" / GH-430)**, claims cited in issues, PRs, ROADMAP entries, or model registries must be backed by retained, verifiable evidence. This directory provides a permanent, auditable home for these empirical test receipts.
     8	
     9	## Directory Structure
    10	
    11	Each testing campaign is recorded in a dedicated subfolder following the naming convention:
    12	
    13	```
    14	TESTS-RESULTS/
    15	├── README.md
    16	└── YYYY-MM-DD+GH-<issue-number>/
    17	    ├── SUMMARY.md                          # Human-readable rollup & configuration details
    18	    ├── error_log.jsonl                     # Structured telemetry & classifier output
    19	    └── <benchmark-name>.jsonl              # Raw baseline measurements & metrics
    20	```
    21	
    22	### Contents of Each Folder
    23	
    24	1. **`SUMMARY.md`**: Overview of the run, duration, model/harness under test, variations matrix, and high-level findings.
    25	2. **`error_log.jsonl`**: Machine-readable JSONL records containing versioned schemas (`schema_version: "1.0"`), iteration metrics (`duration_ms`, `turn_count`, `prompt_tokens`, `completion_tokens`, `total_tokens`), command outputs, and local LLM classifications.
    26	3. **Receipts & Baselines (`*.jsonl`)**: Raw trial outputs backing entries in `HARNESS-MODELS-REGISTRY.md` or active working docs.
    27	
    28	## How to Inspect Results
    29	
    30	To inspect recent runs or summarize triage distributions:
    31	
    32	```bash
    33	python3 utils/ate/scripts/checkin.py --tail 50 \
    34	  --log "TESTS-RESULTS/YYYY-MM-DD+GH-<issue-number>/error_log.jsonl"
    35	```
35:users. Existing whole-folder intake copies it on initialization and update into
46:remains the only authoring source; Pulse and Skills Army mini are generated distributions.
49:1. **Publish from source.** Change the skill in its owning repo and land it there first.
50:   On the designated publisher, preview then apply `intake.py update NAME --source
60:   `python3 "$HOME/git-pulse-sync/Deployed Skills/intake.py" init --adopt-existing`, then
77:its absence must be reported, not mistaken for a successful canonical-source check.
89:1. Read/list the collection and selected source's `SKILL.md`. Explain intended
107:the examples below are templates, not a hardcoded source inventory.
110:python3 /path/to/skills-army-hq/scripts/intake.py init
111:python3 /path/to/skills-army-hq/scripts/intake.py --apply init
112:python3 "$HOME/git-pulse-sync/Deployed Skills/intake.py" list
113:python3 "$HOME/git-pulse-sync/Deployed Skills/intake.py" add /path/to/local-repo/skills/example
114:python3 "$HOME/git-pulse-sync/Deployed Skills/intake.py" --apply add /path/to/local-repo/skills/example
115:python3 "$HOME/git-pulse-sync/Deployed Skills/intake.py" --apply update example
116:python3 "$HOME/git-pulse-sync/Deployed Skills/intake.py" --apply update example --source /new/repo/skills/example
117:python3 "$HOME/git-pulse-sync/Deployed Skills/intake.py" --apply remove example
118:python3 "$HOME/git-pulse-sync/Deployed Skills/intake.py" --apply catalog
119:python3 "$HOME/git-pulse-sync/Deployed Skills/intake.py" targets
120:python3 "$HOME/git-pulse-sync/Deployed Skills/intake.py" --apply targets --id chosen-app --path /verified/app/skills --consumer "Chosen app"
121:python3 "$HOME/git-pulse-sync/Deployed Skills/intake.py" --apply targets --id chosen-app --disable
134:dirty and unmerged working folders are allowed and recorded with commit and digest.
165:  `intake.py --apply update <name> --source <forge>/skills/<name>`, then sync again.
171:Copying instructions does not bundle the source repo's tools, config or services.
172:Record requirements locally using `intake.py --apply prerequisite SKILL "TEXT"`;
180:paths; keep imported payloads, source receipts, targets, history and ZIPs out of the

exec
/bin/zsh -lc "python3 -B -c 'import sys, subprocess; print(\"parent dont_write_bytecode:\", sys.dont_write_bytecode); subprocess.run([sys.executable, \"-c\", \"import sys; print(\\\"child dont_write_bytecode:\\\", sys.dont_write_bytecode)\"], check=True)'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-17340-oelbhd71
 succeeded in 0ms:
child dont_write_bytecode: False
parent dont_write_bytecode: True

exec
/bin/zsh -lc "nl -ba skills/skills-army-hq/SKILL.md | sed -n '43,57p'; nl -ba skills/skills-army-hq/SKILL.md | sed -n '127,139p'; nl -ba relay-automation/new-relay.sh | sed -n '72,95p'; nl -ba relay-automation/relay-turn-lib.sh | sed -n '1210,1246p'; nl -ba AGENTS.md | sed -n '97,117p'; nl -ba AGENTS.md | sed -n '219,235p'; nl -ba utils/py/express.py | sed -n '81,101p'" in /private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/consult-wt-17340-oelbhd71
 succeeded in 0ms:
    43	Every device uses its own Pulse checkout's `Deployed Skills` directly. Do not import those
    44	payloads into a second `~/Documents/Deployed Skills` collection. This SOP supersedes the
    45	GH-508 spike and the former GH-536 secondary-device copy procedure. The owning repository
    46	remains the only authoring source; Pulse and Skills Army mini are generated distributions.
    47	This entire bundle, including this SOP and recovery guidance, travels with the projection.
    48	
    49	1. **Publish from source.** Change the skill in its owning repo and land it there first.
    50	   On the designated publisher, preview then apply `intake.py update NAME --source
    51	   /path/to/owning-repo/skills/NAME` (or `add` for a new skill) against the Pulse root.
    52	   Commit the reviewed portable paths immediately; the Pulse writer cannot rebase a dirty
    53	   tracked tree. Push through the existing Pulse workflow. Do not edit deployed payloads.
    54	2. **Prepare each device's checkout.** Pull the Pulse checkout when its tracked tree is clean.
    55	   Before any local initialization, verify the collection's tracked `.gitignore` excludes
    56	   receipts, pending receipts, targets, catalog, history, locks, backups, staging and caches
    57	   as listed in [recovery.md](references/recovery.md). Ignoring an already tracked file is
   127	
   128	Both scripts accept `--root /chosen/collection` for redirected Documents or another
   129	explicit collection. The default root is `~/git-pulse-sync/Deployed Skills`; `XYZ_SKILLS_ROOT` overrides it,
   130	and explicit `--root` overrides both. Check old environment overrides before operating;
   131	script location does not select a different collection. A custom root is an alternative
   132	for users without Pulse, not an additional mirror on a Pulse-enabled device. Home/path values are computed locally, never copied from a
   133	different user's configuration. Source intake is restricted to local Git repos;
   134	dirty and unmerged working folders are allowed and recorded with commit and digest.
   135	External, absolute, dangling and cyclic payload links are refused. Copies retain
   136	internal relative links, file modes and bytes. Do not run copied `install.sh` files:
   137	their legacy write policies can bypass managed ownership.
   138	
   139	Actual valid immediate skill folders are the desired set. `catalog.md` is generated;
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
    97	Do not claim success without the relevant test, script, or observable proof. If verification was
    98	skipped or failed, say that plainly and include the result.
    99	
   100	An uncommitted `provenance.jsonl` is not proof (GH-430). Any run cited as evidence in an issue, PR,
   101	ROADMAP entry, or decision record must have its `provenance.jsonl` committed in the same PR — a path
   102	you merely ran and can no longer show counts as no claim at all.
   103	
   104	**A check that cannot fail is not a check.** A passing assertion is evidence only once you have seen
   105	it fail: mutate the thing it guards — break the code, transpose the fix, delete the value — and watch
   106	it go red. If you cannot make it fail, it is decorative, and it is worse than nothing because it
   107	reports confidence it never earned. This is the precise way this principle fails while looking
   108	satisfied: you *did* verify, and the verification was hollow. Three examples from GH-377/GH-379, all
   109	of which passed cleanly before they were mutated — an `awk` range that terminated on its own first
   110	line, `not matches -- "$pat"` where the helper already supplied `--` so the check searched for the
   111	literal string `--`, and a telemetry `rc` assertion that no *passing* run could ever exercise.
   112	
   113	**An empty input passes every check.** Before asserting anything about extracted data, assert that
   114	you extracted some: a failed command substitution yields an empty string, a shell redirect creates
   115	the file regardless, and a scanner then reports CLEAN against zero bytes. Size-check the artifact,
   116	or guard the extraction with its own assertion, before trusting a verdict computed from it.
   117	
   219	  itself establish that deleted local behaviour was safe to remove.
   220	- `validate.sh` is the code/runtime gate. `utils/pdda/pdda.sh run` and its targeted
   221	  `utils/pdda/pdda.sh <check>` subcommands are the doc-hygiene gates.
   222	- **Scratch and temporary files go in `temp/`, never the repo root.** `/temp/` is already gitignored
   223	  (`.gitignore:13`). Probes, reproduction scripts, one-off analysis, captured command output,
   224	  half-written notes — anything you would not put in a commit — belongs there or outside the repo
   225	  entirely. **Do not create `scratch-*.md`, `notes-*.md`, `*.tmp` or similar at the repo root.**
   226	
   227	  This is a housekeeping rule with a real failure mode behind it, which is why it is a rail and not a
   228	  preference. Root-level scratch is *untracked*, so it survives branch switches, rebases and
   229	  worktree teardown; it accumulates silently across sessions until nobody can say which agent or
   230	  which lane produced it, or whether it is safe to delete. It also puts unreviewed prose one
   231	  `git add -A` away from a commit — and `marathon-closeout.sh` has already swept 20 unrelated files
   232	  into a lane's PR once (2026-08-10), which is exactly this hazard firing.
   233	
   234	  A file that turns out to be worth keeping gets *promoted* deliberately — into `PROJECT/1-INBOX/`
   235	  as a capture doc, into `test/baselines/` as recorded evidence, or into the CHANGELOG — rather than
    81	
    82	def now_iso():
    83	    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"
    84	
    85	
    86	def die(msg, code=EXIT_ENV):
    87	    sys.stderr.write(msg.rstrip() + "\n")
    88	    sys.exit(code)
    89	
    90	
    91	def refuse(root, rule, reason, issue=None):
    92	    write_tick(root, "express-refused", issue=issue, rule=rule, reason=reason)
    93	    sys.stderr.write("express-refused: rule=%s — %s\n" % (rule, reason))
    94	    sys.exit(EXIT_REFUSED)
    95	
    96	
    97	def write_tick(root, verb, **fields):
    98	    events = os.path.join(root, ".tick", "events")
    99	    ts = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H-%M-%S.%f")[:-3] + "Z"
   100	    target = "gh-%s" % fields.get("issue") if fields.get("issue") else "lane"
   101	    filename = "%s-%s-%s.jsonl" % (ts, verb, target)

codex
There’s a probe residue path the plan misses: `.relay-artifacts/` is checked by a recursive content signature, so ignored bytecode there can still fail the turn. A read-only local probe confirmed that a child Python process does not inherit its parent’s `-B` flag. I’m finishing with the required wording changes and a pre-merge test that exercises scratch containment.

codex
**ANSWER:** PROCEED-WITH-CHANGES. The scope is reasonable, but S1 leaves contradictory instructions in the assembled prompt, S5 does not prove probes survive containment, and the execution lane violates its own test-isolation rule.

I read the referenced implementation. The historical `gh673-final-qa.md` is absent from this checkout, so I could not independently validate the incident narrative. No files were written or repository suites run.

**RECOMMENDATION:** Keep the prose-focused change, fix the complete reviewer prompt, and add one deterministic containment test before merging.

Q1: The worktree exclusion is correct. Measuring whether a forged approval is rejected requires executing the attestation fixtures in `test/gh505-relay-attest.sh:145`, which belongs in a disposable full clone. Provide an explicit escalation path for such measurements; do not relax `AGENTS.md:15`. Ordinary pure-function and read-only data probes remain useful.

Q2: Not reliably: a finding alone need not state the DoD or supported input domain; the scaffold also mandates reviewing pre-existing defects (`relay-automation/new-relay.sh:81`). Sharpen it to: “Name the input predicate affected by the requested change; cite evidence or an explicit requirement supporting that entire predicate. Any unsupported extension requires the three lines.” Specify the falsifier’s expected result and whether it was actually evaluated.

Q3: Deferring changes to five shims is reasonable; the proposed guidance is insufficient. A local read-only probe confirmed parent `python3 -B` → child Python has `dont_write_bytecode=False`. Bytecode inside the seeded artifact directory changes its recursive signature even when gitignored (`relay-automation/relay-turn-lib.sh:715`, `:909`). Use inherited `PYTHONDONTWRITEBYTECODE=1` and an exported absolute scratch `TMPDIR` in the documented command recipe.

Q4: Mutant: delete the `.relay-scratch` exemption at `relay-automation/relay-turn-lib.sh:898`. Every proposed S5 assertion would still pass, including `.pytest_cache` rejection, but an actual scratch-writing probe would set OFFLANE at `:924`. Add a disposable-clone test exercising worktree begin → probe output → worktree end, with a forbidden artifact edit as its negative control.

Q5: The probe allowance does not contradict “Do not edit the artifact” (`skills/relay/SKILL.md:249`). However, S1’s unconditional “Never modify a tracked file” also forbids updating a tracked relay file; explicitly except the required relay updates. Also reconcile `.relay-scratch/` with the blanket `temp/` rule in `AGENTS.md:222`, and scope “any change outside the relay fails” to acknowledge sanctioned scratch and coordination writes (`relay-automation/relay-turn-lib.sh:894`).

NEW DEFECTS (things the plan does not know about; each with file:line and a fix):

- **[Blocker] The assembled prompt still contradicts S1.** `relay-automation/relay-turn-lib.sh:1055` says “verify ONLY with the specific test for the file(s) you changed” and “Do NOT touch any other file.” Reviewers change no source files and would simultaneously be forbidden from running the specified shell tests. **Fix:** make that verification clause producer-only or replace it with role-consistent wording; assess the complete rendered reviewer prompt.

- **[Should] Scratch evidence disappears before another participant can inspect it.** `relay-automation/relay-turn-lib.sh:824` explicitly says scratch is never copied back; `:1385` also deletes root scratch. A finding that merely cites `.relay-scratch/probe.json` loses its evidence. **Fix:** require the command, relevant input, exit status, and decisive output to be copied into the relay finding before handoff. Commit provenance for acceptance runs as required by `AGENTS.md:100`.

- **[Should] The express-refusal receipt cannot happen in the proposed order.** Before implementation, `utils/py/express.py:438` sees no changes and refuses `empty`; an unwired fresh clone fails earlier at `:431`. Furthermore, `refuse()` exits immediately (`:91`), so one invocation does not report both expected surface refusals. **Fix:** omit this unnecessary receipt or run after implementation and hook installation, expecting the first applicable refusal.

- **[Should] Focused tests also require isolation.** Lane step 3 runs the new suite and `test/gh308-frozen-twin-guard.sh` in the task clone; only step 4 moves testing into a disposable clone. `AGENTS.md:15` prohibits `test/*.sh` in a clone whose state matters. **Fix:** run all listed shell suites and mutation controls in the separate disposable full clone.

- **[Should] Another supported scaffolding path omits B.** `skills/relay-xyz/SKILL.md:586` directs operators to `/relay` for scaffolding, whose verbatim template at `skills/relay/SKILL.md:229` retains the old reviewer/producer instructions at `:249`. Updating `new-relay.sh` alone leaves newly created threads without B on that path. **Fix:** update the generic template too, or explicitly limit the guarantee to script-scaffolded threads and document the unsupported path.

- **[Pass] One shared role-note edit is sufficient for the Python bridge.** `utils/py/rtl.py:792` delegates prompt generation to `rtl_turn_prompt`. Keeping enforcement unchanged and avoiding frozen Bash-twin edits is justified.

VERDICT: PROCEED-WITH-CHANGES

Changes required before proceeding (if any):

- Reconcile the complete reviewer prompt, including relay-file and scratch exceptions.
- Tighten S2’s evidence boundary and require durable probe evidence.
- Add the scratch-containment behavioral test and run all suites in a disposable full clone.
- Correct express sequencing and cover the generic scaffolding path.

One thing the other advisor will probably get wrong: Treating ignored `__pycache__` as universally invisible to enforcement—the seeded artifact directory is recursively hashed independently of Git’s ignore rules.
tokens used
89,234
**ANSWER:** PROCEED-WITH-CHANGES. The scope is reasonable, but S1 leaves contradictory instructions in the assembled prompt, S5 does not prove probes survive containment, and the execution lane violates its own test-isolation rule.

I read the referenced implementation. The historical `gh673-final-qa.md` is absent from this checkout, so I could not independently validate the incident narrative. No files were written or repository suites run.

**RECOMMENDATION:** Keep the prose-focused change, fix the complete reviewer prompt, and add one deterministic containment test before merging.

Q1: The worktree exclusion is correct. Measuring whether a forged approval is rejected requires executing the attestation fixtures in `test/gh505-relay-attest.sh:145`, which belongs in a disposable full clone. Provide an explicit escalation path for such measurements; do not relax `AGENTS.md:15`. Ordinary pure-function and read-only data probes remain useful.

Q2: Not reliably: a finding alone need not state the DoD or supported input domain; the scaffold also mandates reviewing pre-existing defects (`relay-automation/new-relay.sh:81`). Sharpen it to: “Name the input predicate affected by the requested change; cite evidence or an explicit requirement supporting that entire predicate. Any unsupported extension requires the three lines.” Specify the falsifier’s expected result and whether it was actually evaluated.

Q3: Deferring changes to five shims is reasonable; the proposed guidance is insufficient. A local read-only probe confirmed parent `python3 -B` → child Python has `dont_write_bytecode=False`. Bytecode inside the seeded artifact directory changes its recursive signature even when gitignored (`relay-automation/relay-turn-lib.sh:715`, `:909`). Use inherited `PYTHONDONTWRITEBYTECODE=1` and an exported absolute scratch `TMPDIR` in the documented command recipe.

Q4: Mutant: delete the `.relay-scratch` exemption at `relay-automation/relay-turn-lib.sh:898`. Every proposed S5 assertion would still pass, including `.pytest_cache` rejection, but an actual scratch-writing probe would set OFFLANE at `:924`. Add a disposable-clone test exercising worktree begin → probe output → worktree end, with a forbidden artifact edit as its negative control.

Q5: The probe allowance does not contradict “Do not edit the artifact” (`skills/relay/SKILL.md:249`). However, S1’s unconditional “Never modify a tracked file” also forbids updating a tracked relay file; explicitly except the required relay updates. Also reconcile `.relay-scratch/` with the blanket `temp/` rule in `AGENTS.md:222`, and scope “any change outside the relay fails” to acknowledge sanctioned scratch and coordination writes (`relay-automation/relay-turn-lib.sh:894`).

NEW DEFECTS (things the plan does not know about; each with file:line and a fix):

- **[Blocker] The assembled prompt still contradicts S1.** `relay-automation/relay-turn-lib.sh:1055` says “verify ONLY with the specific test for the file(s) you changed” and “Do NOT touch any other file.” Reviewers change no source files and would simultaneously be forbidden from running the specified shell tests. **Fix:** make that verification clause producer-only or replace it with role-consistent wording; assess the complete rendered reviewer prompt.

- **[Should] Scratch evidence disappears before another participant can inspect it.** `relay-automation/relay-turn-lib.sh:824` explicitly says scratch is never copied back; `:1385` also deletes root scratch. A finding that merely cites `.relay-scratch/probe.json` loses its evidence. **Fix:** require the command, relevant input, exit status, and decisive output to be copied into the relay finding before handoff. Commit provenance for acceptance runs as required by `AGENTS.md:100`.

- **[Should] The express-refusal receipt cannot happen in the proposed order.** Before implementation, `utils/py/express.py:438` sees no changes and refuses `empty`; an unwired fresh clone fails earlier at `:431`. Furthermore, `refuse()` exits immediately (`:91`), so one invocation does not report both expected surface refusals. **Fix:** omit this unnecessary receipt or run after implementation and hook installation, expecting the first applicable refusal.

- **[Should] Focused tests also require isolation.** Lane step 3 runs the new suite and `test/gh308-frozen-twin-guard.sh` in the task clone; only step 4 moves testing into a disposable clone. `AGENTS.md:15` prohibits `test/*.sh` in a clone whose state matters. **Fix:** run all listed shell suites and mutation controls in the separate disposable full clone.

- **[Should] Another supported scaffolding path omits B.** `skills/relay-xyz/SKILL.md:586` directs operators to `/relay` for scaffolding, whose verbatim template at `skills/relay/SKILL.md:229` retains the old reviewer/producer instructions at `:249`. Updating `new-relay.sh` alone leaves newly created threads without B on that path. **Fix:** update the generic template too, or explicitly limit the guarantee to script-scaffolded threads and document the unsupported path.

- **[Pass] One shared role-note edit is sufficient for the Python bridge.** `utils/py/rtl.py:792` delegates prompt generation to `rtl_turn_prompt`. Keeping enforcement unchanged and avoiding frozen Bash-twin edits is justified.

VERDICT: PROCEED-WITH-CHANGES

Changes required before proceeding (if any):

- Reconcile the complete reviewer prompt, including relay-file and scratch exceptions.
- Tighten S2’s evidence boundary and require durable probe evidence.
- Add the scratch-containment behavioral test and run all suites in a disposable full clone.
- Correct express sequencing and cover the generic scaffolding path.

One thing the other advisor will probably get wrong: Treating ignored `__pycache__` as universally invisible to enforcement—the seeded artifact directory is recursively hashed independently of Git’s ignore rules.
