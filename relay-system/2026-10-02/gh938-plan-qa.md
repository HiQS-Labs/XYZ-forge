# RELAY · GH-938 (XYZ-forge) relay-xyz managed-setup docs plan + post-merge deployment checklist — plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 3 / 3

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
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-938-xyz-forge-relay-xyz-managed-setup-docs-plan-post-merge-deployment-checklist-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh938-plan-qa-artifact.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-02

### Artifact — gh938-plan-qa-artifact.md
````
# GH-938 plan QA packet (XYZ-forge) — branch fix/gh938-relay-xyz-managed-setup @ d6825c7e, base origin/development 5212dae4

## What to review
The PLAN (doc below) for https://github.com/HiQS-Labs/XYZ-forge/issues/938, including its
"Post-merge deployment checklist", and the DRAFT replacement text for the SKILL.md section.
Your worktree is an OLDER harness checkout; do NOT rely on its copies of these files. Every source
excerpt below is quoted verbatim from origin/development @ 5212dae4 (or, where labelled, from the
Mac Mini's deployed Skills Army HQ copy) with line numbers.

## Operator requirements (binding)
1. Docs-only change to skills/1-hourly/relay-xyz/SKILL.md "First-time setup": skip install.sh when
   ~/.claude/skills/relay-xyz already resolves into a Skills Army "Deployed Skills" collection
   (readlink check); point those machines to find-harness.sh --check and ~/.config/xyz/harness
   (command-scoped XYZ_HARNESS fallback).
2. install.sh managed-detection is OUT of scope (deferred, noted in plan/issue).
3. No new test suites or validate.sh TESTS entries (AGENTS.md "No new tests", GH-831). Keep
   test/find-harness.sh pins (:41, :43) and the other suites reading this SKILL.md (gh278, gh346,
   gh681, path-integrity) true. Mirror twin copies only if repo policy requires it (recon: none).
4. Plan must contain a post-merge deployment checklist covering: merge commit + hosted CI + next
   wave-reconcile; publisher selection; publisher refresh of canonical clone, intake.py update
   preview then --apply with --source, digest check, Pulse commit; Mini: pulse pull, sync.py
   --status clean, readlink -f into Deployed Skills, deployed SKILL.md has new text,
   find-harness.sh --check from ~ passes WITHOUT XYZ_HARNESS; no new untracked links in
   ~/.codex/skills or ~/.gemini/antigravity{,-cli}/skills; Mac Studio same; rollback; close #938
   only after the Mini check with evidence. Every command/flag must match the real scripts.
5. Not in this PR: merge, deploy, any intake --apply, touching the Mini's XYZ-forge clone.

## Operational envelope
Single-operator fleet of 4 Macs. Grade against the requirements above and commensurate complexity
for a one-section markdown edit. Do not demand new suites, new gate machinery, or multi-tenant threat
models. Behaviour-change requests need Observed input / Affected scope / Falsifier (GH-681).

## Questions
Q1. Are the plan's recon claims grounded in the quoted paths/lines? Any wrong citation?
Q2. Does the draft section satisfy requirement 1 and keep test/find-harness.sh:41/:43 and
    test/path-integrity.sh Check B true (no unresolvable repo-path tokens)?
Q3. Is any requirement missing from plan or checklist? Is every checklist command/flag valid against
    the quoted intake.py / sync.py / gh / git usage (global options before subcommands, --source
    required on the Mini, Unchanged short-circuit, --status read-only, --canonical drift)?
Q4. Is the checklist ordering, publisher choice (GH-881: any device may publish, one at a time), and
    rollback sound and falsifiable? Is "close #938 only after the Mini check" preserved?
Q5. Is the rating 40/35/50/85 grounded (appeal neutral)? Is the gate selection (full ./validate.sh,
    since utils/ci-route.sh marks every relay-xyz file full-gate) right?
Q6. Anything that should be deferred rather than done, or vice versa?

---
## A. The plan (PROJECT/2-WORKING/GH-938-RELAY-XYZ-MANAGED-SETUP.md @ d6825c7e)
---
gh_issue: 938
source: https://github.com/HiQS-Labs/XYZ-forge/issues/938
title: "relay-xyz SKILL.md: First-time setup tells Skills Army-managed Macs to run install.sh"
status: active
created: 2026-10-02
updated: 2026-10-02
owner: XYZ Forge maintainers
doc_type: bugfix
branch: fix/gh938-relay-xyz-managed-setup
effort: 1
complexity: 1
risk: 1
phases: 1
non_goals:
  - No change to install.sh (managed-collection detection is deferred; see Deferred)
  - No change to find-harness.sh, Skills Army HQ scripts, or any app link
  - No new test suite or validate.sh TESTS entry (GH-831)
  - No deployment to any Mac in this PR; deployment is the post-merge checklist below
goal: >
  A machine whose relay-xyz link already resolves into a Skills Army HQ Deployed Skills collection
  is told to skip install.sh and go to the locator, so following the skill creates no unmanaged links.
---

# GH-938: relay-xyz first-time setup on Skills Army-managed Macs

## Status

| What was just completed | What's next |
|---|---|
| Intake parked (rated 40/35/50/85), recon at `5212dae4`, plan written. | Codex plan QA via relay-xyz; then the SKILL.md edit, focused suites, one full gate, final Codex QA, ready PR. |

## Rating — 2026-10-02: `40/35/50/85` (priority/severity/appeal/effort)

- **Severity 35:** Following the documented step on a managed Mac fails (exit 1 on live links) and can
  create app links Skills Army HQ does not own, in roots it does not target. Nothing is lost and the
  links are removable; the skill already works there. Recoverable, low reach (operator Macs).
- **Priority 40:** Operator asked for it now as the follow-on to #856's deployment. Recurrence window
  2026-09-19–10-02: #856 (adjacent: locator assumed the install.sh layout) and #938. Preceding window
  2026-09-05–18: #678 (installers replaced managed links) and #660 (deployed-skill drift). Same
  family (repo docs/installers assuming the pre-Skills-Army layout), no rising rate.
- **Appeal 50:** Neutral; no operator score given.
- **Effort 85:** One markdown section. Cheap to write; the full gate (relay-xyz is a full-gate path)
  is the main cost.

## Recon — observed at `5212dae4` (origin/development, 2026-10-02)

- `skills/1-hourly/relay-xyz/SKILL.md:65-79` ("First-time setup on a new clone or machine") tells
  every clone/machine to run `bash skills/1-hourly/relay-xyz/install.sh` and says it "replaces a
  stale/dangling symlink". No exception for managed machines.
- `skills/1-hourly/relay-xyz/install.sh:42-70`: a live link that is not this copy is refused
  (GH-678) and the script exits 1; absent roots (`~/.codex/skills`, `~/.gemini/antigravity/skills`,
  `~/.gemini/antigravity-cli/skills`) get `mkdir -p` and a new link to whichever copy ran it.
- Skills Army HQ (`skills/3-weekly/skills-army-hq/SKILL.md`): "Do not run copied `install.sh`
  files"; only `intake.py`/`sync.py` mutate the collection or app links. Deployed SOP (GH-672): app
  links point into the device's Pulse checkout `Deployed Skills/`.
- Since #856/#936, `find-harness.sh` (same folder) resolves a copied deployment via the per-device
  config `${XDG_CONFIG_HOME:-$HOME/.config}/xyz/harness` or a bounded clone search, and `--check`
  prints the command that saves the config. `SKILL.md:81-111` already documents this; the setup
  section just never routes managed machines there.
- Mac Mini observation (2026-10-02 ~6:50 PM PT, read-only): `~/.claude/skills`, `~/.agents/skills`,
  `~/.gemini/config/skills`, `~/.zcode/skills`, `~/.grok-bot/skills` → `relay-xyz` all resolve to
  `~/Documents/GitHub/rebalance-git-pulse/Deployed Skills/relay-xyz`; the three install.sh-only
  roots above have no `relay-xyz` entry; `sync.py --status` clean.
- Consumers of this file that the edit must keep true:
  - `test/find-harness.sh:40-43` — SKILL.md contains `$HOME/.claude/skills/relay-xyz/find-harness.sh`,
    and has no line that is exactly `bash skills/1-hourly/relay-xyz/find-harness.sh --check`.
  - `test/path-integrity.sh` Check B scans this file for repo-path tokens (`skills/…`, `test/…`,
    `relay-automation/…`, `bin/…` ending `.sh`/`.md`/`.tar.gz`); every token must resolve. App
    discovery paths (`~/.claude/skills/…` etc.) are blanked first.
  - `test/gh278-turn-timeout-parity.sh:60`, `test/gh346-gateway-allowlists.sh:401`,
    `test/gh681-reviewer-probe-rules.sh:94-101` grep other sections (timeouts, deepseek, reviewer
    rules); untouched by this edit.
  - `utils/ci-route.sh:67,342` and `test/ci-route.sh:176`: every relay-xyz file is a full-gate path,
    so this landing qualifies on the Large tier (full registry).
- No twin/mirror of this section: the phrase appears only in this SKILL.md, CHANGELOG history and an
  old relay thread. Deployed copies are produced by Skills Army HQ after merge, not by this PR.
- Observed, out of scope: `SKILL.md:207-209` says `install.sh` "writes only into `~/.claude/skills/`";
  it writes five app roots. Recorded for the deferred install.sh follow-up, not edited here.

## Plan (one phase)

1. Rewrite only the "First-time setup" section of `skills/1-hourly/relay-xyz/SKILL.md`:
   - Lead with a check: `readlink ~/.claude/skills/relay-xyz` (or the same entry in the app's skills
     root).
   - **Managed** (resolves into a `Deployed Skills/relay-xyz` folder): skip `install.sh`; Skills Army
     HQ owns the links (`sync.py`); go to the locator, run its `--check`; if no harness resolves,
     save the canonical clone with the command `--check` prints (`~/.config/xyz/harness`), or prefix
     one command with `XYZ_HARNESS=…`. No shell startup exports.
   - **Not managed** (no link, or a dangling one): keep the existing `install.sh` instruction, which
     is still correct for a maintained primary clone.
   - Keep the two `test/find-harness.sh` pins true; add no unresolvable repo-path tokens.
   Verify inline: `bash test/find-harness.sh`, `bash test/path-integrity.sh`,
   `bash test/gh681-reviewer-probe-rules.sh`, `bash test/gh346-gateway-allowlists.sh`,
   `bash test/gh278-turn-timeout-parity.sh` green; `utils/pdda/pdda.sh run` 0 errors.
2. CHANGELOG entry (PDDA rules); update this doc's Status.
3. Full gate once on the final approved commit, in a disposable full clone (relay-xyz is full-gate);
   receipt and `provenance.jsonl` under `TESTS-RESULTS/2026-10-02+GH-938/`.
4. Final Codex relay QA on the diff; ready PR to `development` with `Closes #938` and the checklist.

## Acceptance and falsifiers

- **Wording present (falsifiable):** `grep -n 'Deployed Skills' skills/1-hourly/relay-xyz/SKILL.md`
  finds the managed-skip instruction inside the First-time setup section, before the `install.sh`
  command. Red control: the same grep on `5212dae4` finds no such line in that section.
- **Pins stay true:** `test/find-harness.sh` and `test/path-integrity.sh` pass. Red control for the
  path scan (manual, recorded): temporarily add a bogus `skills/1-hourly/relay-xyz/nope.sh` token,
  see `path-integrity.sh` fail, revert.
- **Behaviour unchanged:** no change to any `.sh`; `git diff --stat origin/development` lists only
  SKILL.md, CHANGELOG.md, this doc, the ledger dump/DB and the TESTS-RESULTS receipt.
- **Gate:** full `./validate.sh` on the final approved commit; failures attributable to this diff
  block the PR; pre-existing/environment failures are recorded as such with evidence.
- **Deployment (after merge, not this PR):** the Mini checks in the checklist below pass; #938 closes
  only after them.

## Risks and rollback

- Risk: wording breaks a grep-based suite reading this file → caught by the focused suites above and
  the full gate. Rollback: revert the PR (docs-only, Easy). Deployed copies roll back per the
  checklist's rollback step.

## Deferred

- `install.sh` managed-collection detection (skip and exit 0 when a live app link resolves into a
  collection with `.deploy-skills.json`) and the `SKILL.md:207-209` wording. Deferred: behaviour
  change to an installer that `test/gh678-installer-live-links.sh` pins for every skill, and the new
  path has no existing covering suite (GH-831 forbids adding one).

## Post-merge deployment checklist

Not executed by this PR. Run in order; stop at the first failure. `C` = the device's collection
(`<Pulse checkout>/Deployed Skills`); on the Mini the Pulse checkout is
`~/Documents/GitHub/rebalance-git-pulse`, on the Mac Studio `~/git-pulse-sync` (or `$XYZ_SKILLS_ROOT`).

1. **Landing.** `gh pr view <PR> -R HiQS-Labs/XYZ-forge --json state,mergeCommit` → `MERGED`; note
   `<sha>`. `gh run list -R HiQS-Labs/XYZ-forge --workflow CI --commit <sha>` → the push run
   completed `success` (the ubuntu canary is advisory; record any red). `gh run list -R
   HiQS-Labs/XYZ-forge --workflow "Wave reconciliation" --limit 5` → the `pull_request` run for this
   PR (or the next scheduled run) completed `success`; no open `hosted-reconcile-attention` issue
   for it.
2. **Choose the publisher.** Per the operator ruling recorded in CHANGELOG (GH-881), any device may
   publish, but exactly one device publishes this change. It needs a clean canonical clone on
   `development`: `git -C <clone> status -sb` shows no local commits or changes, then
   `git -C <clone> pull --ff-only`, and `git -C <clone> rev-parse HEAD` contains `<sha>`
   (`git -C <clone> merge-base --is-ancestor <sha> HEAD`). The Mini's `~/Documents/GitHub/XYZ-forge`
   does not qualify today (local relay commits, behind origin); use the Mac Studio's clone, or settle
   the Mini clone first.
3. **Publish (on the publisher).**
   - Preview: `python3 "$C/intake.py" --root "$C" update relay-xyz --source
     "<clone>/skills/1-hourly/relay-xyz"`. Expect `before`/`after` digests and `commit` = `<clone>`
     HEAD. `Unchanged: relay-xyz` means it is already published; stop. `--source` is required: the
     Mini's receipt records the collection itself as source, which `intake.py` refuses (overlap).
   - Apply: the same command with `--apply` before `update`. It writes a verified backup ZIP under
     `$C/backups/`.
   - Verify: `python3 "$C/intake.py" --root "$C" list` shows the relay-xyz receipt digest equal to the
     preview's `after`, `commit` = `<clone>` HEAD, `dirty: false`.
     `python3 "$C/sync.py" --root "$C" --status --canonical "<clone>"` → no errors, relay-xyz not
     `DRIFTED`.
   - Commit immediately (the Pulse writer cannot rebase a dirty tracked tree):
     `git -C <pulse> add -- "Deployed Skills/relay-xyz"` (plus `"Deployed Skills/README.md"` if the
     apply changed it), `git -C <pulse> commit -m "vendor: publish relay-xyz from XYZ-forge@<sha>
     (PR #<PR>, GH-938)"`, then push through the Pulse workflow (`git -C <pulse> push`, or the next
     Pulse cycle). `git -C <pulse> status -sb` shows nothing ahead.
4. **Mac Mini.**
   - `git -C ~/Documents/GitHub/rebalance-git-pulse status --porcelain --untracked-files=no` is
     empty, then `git -C ~/Documents/GitHub/rebalance-git-pulse pull` (or wait for its Pulse cycle);
     `git -C ~/Documents/GitHub/rebalance-git-pulse log -1 --format=%H -- "Deployed Skills/relay-xyz"`
     is the publish commit.
   - `python3 "$C/sync.py" --root "$C" --status` → `errors: []`, no relay-xyz actions or conflicts.
   - `readlink -f ~/.claude/skills/relay-xyz` → `$C/relay-xyz` (same for `~/.agents/skills`,
     `~/.gemini/config/skills`, `~/.zcode/skills`, `~/.grok-bot/skills`).
   - Deployed bytes match the merge: `gh api "repos/HiQS-Labs/XYZ-forge/contents/skills/1-hourly/relay-xyz/SKILL.md?ref=<sha>"
     -H "Accept: application/vnd.github.raw" | diff - "$C/relay-xyz/SKILL.md"` and the same for
     `find-harness.sh` → no output. `grep -n "Deployed Skills" "$C/relay-xyz/SKILL.md"` shows the new
     managed-skip line.
   - From `~`: `cd ~ && env -u XYZ_HARNESS -u XYZ_REPO_ROOT bash ~/.claude/skills/relay-xyz/find-harness.sh --check`
     → exit 0 with `via=config` or `via=search` (this also proves the #856/#936 locator reached the
     Mini). A behind-upstream warning for the clone is advisory.
   - No unmanaged links: `ls -ld ~/.codex/skills/relay-xyz ~/.gemini/antigravity/skills/relay-xyz
     ~/.gemini/antigravity-cli/skills/relay-xyz` → all "No such file or directory".
5. **Mac Studio, when online.** The same step 4 with its Pulse checkout (`~/git-pulse-sync`) and
   `C="$HOME/git-pulse-sync/Deployed Skills"` (or `$XYZ_SKILLS_ROOT`). Other Macs the same when next
   online; record which were checked.
6. **Rollback (if a check fails after publish).** On the publisher, re-publish the previous payload
   from a clean checkout of the pre-merge commit: `git clone https://github.com/HiQS-Labs/XYZ-forge.git
   <tmp> && git -C <tmp> checkout <pre-merge sha>`, then preview/apply `intake.py --root "$C" update
   relay-xyz --source "<tmp>/skills/1-hourly/relay-xyz"`, commit and push as in step 3; devices pull.
   (Alternatives in Skills Army HQ `references/recovery.md`: the verified backup ZIP or the staged
   prior folder.) If the doc itself is wrong, revert the PR on `development` through the normal lane.
7. **Close #938** only after step 4 passes on the Mini. Comment on #938 with the merge sha, CI and
   reconcile run URLs, the publish commit, and the step-4 outputs (sync status, readlink, diff,
   `--check` line).

---
## B. DRAFT replacement for SKILL.md lines 65-79 (section heading through the paragraph before '## Preconditions')
## First-time setup on a new clone or machine (make the skill discoverable)

First check whether Skills Army HQ already manages this skill on the machine:

```bash
readlink ~/.claude/skills/relay-xyz   # or the relay-xyz entry in your app's skills root
```

**Managed by Skills Army HQ — skip `install.sh`.** If the link resolves into a `Deployed Skills/relay-xyz`
folder, the skill is already discoverable and Skills Army HQ owns the link; its rule is not to run copied
`install.sh` files. Running it there exits 1 on the live link (GH-678 keeps it) and can add links in app
roots the collection does not target. Manage links with Skills Army HQ (`sync.py`) and go straight to the
locator below: run its `--check` from the installed path. If it does not resolve a harness, save your
canonical XYZ-forge clone with the one-line command `--check` prints (`${XDG_CONFIG_HOME:-$HOME/.config}/xyz/harness`),
or prefix a single command with `XYZ_HARNESS=/path/to/XYZ-forge`. Do not export it from shell startup files.

**Not managed (no link, or a dangling one).** This repo keeps its skills in top-level `skills/`, which
Claude Code does **not** scan. A session finds `relay-xyz` only if it's symlinked into `~/.claude/skills/`.
A fresh clone or second machine without Skills Army HQ has no such symlink, so the skill is invisible in
**every** session there — the "other VS Code sessions can't find the relay-xyz files" failure. Fix it
**once per maintained clone** (idempotent, self-locating, no hardcoded path):

```bash
bash skills/1-hourly/relay-xyz/install.sh   # symlinks this clone's skills/1-hourly/relay-xyz into ~/.claude/skills/
```

It also replaces a stale/dangling symlink and verifies `find-harness.sh` resolves the harness. The
locator below handles *where the harness scripts live*; this step handles *whether Claude Code can
load the skill at all* — a layer the locator can't reach, since it runs only after the skill loads.

---
## C. skills/1-hourly/relay-xyz/SKILL.md @ 5212dae4, lines 51-120 and 192-210 (cat -n)
    51	## When to use
    52	
    53	- "Run an automated relay" / "drive this relay to completion" / "run the relay harness."
    54	- "Have Codex or agy review `<file>` end-to-end."
    55	- Setting up the all-Claude hands-free `/loop` poll so two Claude windows self-serialize.
    56	- Running automated relays in **two different repos at the same time on one machine** — see
    57	  [Concurrent relays across repos](#concurrent-relays-across-repos-same-machine) (each repo needs its own
    58	  vendored `.xyz/`).
    59	- You have a relay thread (or are about to scaffold one with `/relay`); the current working tree may
    60	  be a foreign repo if the locator can reach a canonical XYZ-forge harness.
    61	
    62	**Not** for: scaffolding a brand-new thread from scratch (that's `/relay`), or work that needs a human checkpoint between every turn (use plain `/relay`
    63	manual mode).
    64	
    65	## First-time setup on a new clone or machine (make the skill discoverable)
    66	
    67	This repo keeps its skills in top-level `skills/`, which Claude Code does **not** scan. A session
    68	finds `relay-xyz` only if it's symlinked into `~/.claude/skills/`. A fresh clone or second machine has
    69	no such symlink, so the skill is invisible in **every** session there — the "other VS Code sessions
    70	can't find the relay-xyz files" failure. Fix it **once per clone** (idempotent, self-locating, no
    71	hardcoded path):
    72	
    73	```bash
    74	bash skills/1-hourly/relay-xyz/install.sh   # symlinks this clone's skills/1-hourly/relay-xyz into ~/.claude/skills/
    75	```
    76	
    77	It also replaces a stale/dangling symlink and verifies `find-harness.sh` resolves the harness. The
    78	locator below handles *where the harness scripts live*; this step handles *whether Claude Code can
    79	load the skill at all* — a layer the locator can't reach, since it runs only after the skill loads.
    80	
    81	## Preconditions — locate the harness (bundled locator, never hardcode a path)
    82	
    83	`relay-xyz` ships its own device-agnostic locator, [`find-harness.sh`](find-harness.sh), beside this
    84	skill. It checks an explicit override, a caller's vendored harness, the current repo, its own
    85	installed location, a per-Mac config at `${XDG_CONFIG_HOME:-$HOME/.config}/xyz/harness`, and bounded
    86	canonical XYZ-forge clone locations. A copied Skills Army deployment therefore works from a foreign
    87	repo. `--check` shows a command to save the chosen canonical harness in that config and warns when
    88	its cached upstream is ahead. It never fetches while checking.
    89	
    90	Run this first. It finds the locator, exports the harness env, `cd`s into the clone that ships the
    91	harness, and prints a one-glance readiness line:
    92	
    93	```bash
    94	# Find the bundled locator. The skill installs at one of these — all anchored on $HOME or
    95	# the CWD, never an absolute machine path:
    96	for L in "${XYZ_HARNESS:+$XYZ_HARNESS/skills/1-hourly/relay-xyz/find-harness.sh}" \
    97	         "$HOME/.claude/skills/relay-xyz/find-harness.sh" \
    98	         "$HOME/.codex/skills/relay-xyz/find-harness.sh" \
    99	         "$HOME/.gemini/config/skills/relay-xyz/find-harness.sh" \
   100	         "$HOME/.gemini/antigravity/skills/relay-xyz/find-harness.sh" \
   101	         "$HOME/.gemini/antigravity-cli/skills/relay-xyz/find-harness.sh" \
   102	         "./.claude/skills/relay-xyz/find-harness.sh" \
   103	         "$(git rev-parse --show-toplevel 2>/dev/null)/skills/1-hourly/relay-xyz/find-harness.sh"; do
   104	  [ -n "$L" ] && [ -x "$L" ] && break
   105	done
   106	[ -x "$L" ] || { echo "relay-xyz: locator not found — set XYZ_HARNESS to your XYZ-forge clone"; exit 1; }
   107	
   108	eval "$("$L" --env)"   # exports HARNESS, TICK, TICK_REPO_ROOT, RELAY_HAS_{TICK,CODEX,AGY,COMMANDCODE,DEEPSEEK}
   109	cd "$HARNESS"
   110	"$L" --check           # prints: harness path + which Path-A workers (tick/codex/agy/cmd/dsh) are on PATH
   111	```
   112	
   113	After this, `$HARNESS` is the harness repo root, `$TICK` is the absolute `bin/tick`, and
   114	`TICK_REPO_ROOT` points `tick` at that clone's event log. The relay/turn scripts self-resolve their
   115	own location (`$(dirname "$BASH_SOURCE")/..`), so invoke them with **repo-relative** paths exactly as
   116	the [relay automation README](https://github.com/HiQS-Labs/XYZ-forge/blob/development/relay-automation/README.md) shows.
   117	The relay always operates on **the
   118	harness clone** (its `.tick/` log and guarded git root live there), whatever repo you launched from —
   119	so a clone with only `relay-system/` thread files still drives the real harness next door.
   120	
   192	## Per-repo persistence (don't cache a path)
   193	
   194	Once a target repo has used relay-xyz once, don't leave behind a machine-specific breadcrumb so the
   195	next session skips the "run `find-harness.sh` first" gate above. The only two persistence channels
   196	Claude Code **auto-loads** are:
   197	
   198	- **The target repo's memory** — seed a line the first time a run succeeds there, e.g. "this repo uses
   199	  relay-xyz; run `find-harness.sh --check` first."
   200	- **That repo's own `CLAUDE.md`, by skill name** — a pointer such as "for automated relays, use the
   201	  `relay-xyz` skill" (not a path).
   202	
   203	Either breadcrumb must be a **portable pointer** — the skill name or the `find-harness.sh` command —
   204	**never a cached absolute path and never a bare root pointer file** dropped into the target repo. A
   205	bare file isn't auto-loaded (a skimming agent skips it exactly like it skips this doc's own body), it's
   206	machine-specific (breaks on the next clone or device), a stale cached path is *worse* than no path at
   207	all, and cleaning one up later has cross-repo blast radius. **relay-xyz never auto-installs any file
   208	into a target repo** — only `install.sh` writes anything, and it writes only into `~/.claude/skills/`
   209	on the machine running it, never into the target repo itself.
   210	

## D. skills/1-hourly/relay-xyz/install.sh @ 5212dae4, lines 1-82
     1	#!/usr/bin/env bash
     2	#
     3	# install.sh — make relay-xyz discoverable to Claude Code, Codex, and Gemini / Antigravity from THIS clone.
     4	#
     5	# THE problem this fixes: the repo keeps its skills in top-level skills/, a directory
     6	# agent runtimes do NOT scan by default. A session only finds relay-xyz if it is symlinked
     7	# into the environment skills dir (~/.claude/skills/, ~/.codex/skills/, ~/.gemini/config/skills/,
     8	# ~/.gemini/antigravity/skills/, etc.). A fresh clone / other machine has no such symlink,
     9	# so the skill is invisible in EVERY session there. This script creates those symlinks —
    10	# idempotently, self-locating, with no hardcoded machine path — so any clone can make itself
    11	# discoverable in one command.
    12	#
    13	#   bash skills/1-hourly/relay-xyz/install.sh          # install / repair symlinks
    14	#
    15	# Each destination has its own override: CLAUDE_SKILLS_DIR, CODEX_SKILLS_DIR,
    16	# GEMINI_CONFIG_SKILLS_DIR, ANTIGRAVITY_SKILLS_DIR, ANTIGRAVITY_CLI_SKILLS_DIR.
    17	#
    18	# Safe to re-run. Replaces stale/dangling symlinks and backs up existing real directories before linking.
    19	set -u
    20	
    21	# --- resolve this script's real directory (symlink-safe; bash 3.2 / macOS) ---
    22	_src="${BASH_SOURCE[0]}"
    23	while [ -h "$_src" ]; do
    24	  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
    25	  _src="$(readlink "$_src")"
    26	  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
    27	done
    28	SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"   # …/skills/1-hourly/relay-xyz
    29	SKILL_NAME="relay-xyz"
    30	
    31	install_one() {
    32	  _label="$1"
    33	  _dest="$2"
    34	  _link="$_dest/$SKILL_NAME"
    35	
    36	  if [ -e "$_dest" ] && [ ! -d "$_dest" ]; then
    37	    echo "$SKILL_NAME: $_dest exists and is not a directory — skipping $_label." >&2
    38	    return 1
    39	  fi
    40	  mkdir -p "$_dest"
    41	
    42	  if [ -L "$_link" ]; then
    43	    if [ -e "$_link" ] && [ "$(cd -P "$_link" >/dev/null 2>&1 && pwd)" = "$SELF_DIR" ]; then
    44	      echo "$SKILL_NAME: already installed for $_label → $_link -> $SELF_DIR"
    45	      return 0
    46	    fi
    47	    if [ -L "$_link" ] && [ -e "$_link" ]; then
    48	      # GH-678: a live link that is not ours belongs to another installer or to a managed
    49	      # Skills Army collection. Only a dangling link is stale enough to replace.
    50	      echo "$SKILL_NAME: $_link already points at $(readlink "$_link") — not replacing a live link." >&2
    51	      echo "  Remove it yourself if that is intended." >&2
    52	      return 1
    53	    fi
    54	    rm -f "$_link"
    55	  elif [ -e "$_link" ]; then
    56	    _backup="${_link}.bak-$(date +%Y%m%d%H%M%S)"
    57	    echo "$SKILL_NAME: $_link exists as a real directory/file — backing up to $_backup before linking."
    58	    mv "$_link" "$_backup"
    59	  fi
    60	
    61	  ln -s "$SELF_DIR" "$_link"
    62	  echo "$SKILL_NAME: installed for $_label → $_link -> $SELF_DIR"
    63	}
    64	
    65	rc=0   # GH-678: a refused or skipped target must be visible in the exit code, as in the sibling installers
    66	install_one "Claude Code" "${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}" || rc=1
    67	install_one "Codex" "${CODEX_SKILLS_DIR:-$HOME/.codex/skills}" || rc=1
    68	install_one "Gemini (Config)" "${GEMINI_CONFIG_SKILLS_DIR:-$HOME/.gemini/config/skills}" || rc=1
    69	install_one "Gemini (Antigravity)" "${ANTIGRAVITY_SKILLS_DIR:-$HOME/.gemini/antigravity/skills}" || rc=1
    70	install_one "Gemini (Antigravity CLI)" "${ANTIGRAVITY_CLI_SKILLS_DIR:-$HOME/.gemini/antigravity-cli/skills}" || rc=1
    71	
    72	# --- verify the chain the skill actually depends on ---
    73	if [ -x "$SELF_DIR/find-harness.sh" ]; then
    74	  H="$("$SELF_DIR/find-harness.sh" --root 2>/dev/null || true)"
    75	  if [ -n "$H" ]; then
    76	    echo "relay-xyz: harness resolves → $H"
    77	  else
    78	    echo "relay-xyz: WARNING — find-harness.sh could not resolve the harness root." >&2
    79	    echo "  Set XYZ_HARNESS=/path/to/your/XYZ-forge clone." >&2
    80	  fi
    81	fi
    82	exit "$rc"

## E. test/find-harness.sh @ 5212dae4, lines 1-45
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# find-harness.sh — GH-70 Phase 2: the concurrency-readiness warning in `find-harness.sh --check`.
     5	# A foreign repo with no local .xyz/ resolves to the CENTRALIZED harness (shared global driver lock),
     6	# so --check must WARN (fail-open, exit 0) and point at xyz-vendor.sh. A vendored repo (its own .xyz/)
     7	# or the harness clone itself must NOT warn.
     8	
     9	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    10	REPO="$(cd "$HERE/.." && pwd)"
    11	FH="$REPO/skills/1-hourly/relay-xyz/find-harness.sh"
    12	SKILL="$REPO/skills/1-hourly/relay-xyz/SKILL.md"
    13	pass=0; fail=0
    14	ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
    15	mkrepo() { _repo="$(mktemp -d "${TMPDIR:-/tmp}/fh-case.XXXXXX")"; git -C "$_repo" init -q; printf '%s\n' "$_repo"; }
    16	seed_vendored_harness() {
    17	  _repo="$1"
    18	  mkdir -p "$_repo/.xyz/relay-automation" "$_repo/.xyz/bin"
    19	  printf '#!/usr/bin/env bash\n:\n' > "$_repo/.xyz/relay-automation/relay-drive.sh"; chmod +x "$_repo/.xyz/relay-automation/relay-drive.sh"
    20	  printf '#!/usr/bin/env bash\n:\n' > "$_repo/.xyz/bin/tick"; chmod +x "$_repo/.xyz/bin/tick"
    21	}
    22	seed_index_path() {
    23	  _repo="$1"; _path="$2"
    24	  _blob="$(printf 'fixture\n' | git -C "$_repo" hash-object -w --stdin)"
    25	  git -C "$_repo" update-index --add --cacheinfo 100644,"$_blob","$_path"
    26	}
    27	seed_case_collision() {
    28	  _repo="$1"
    29	  seed_index_path "$_repo" "relay-system/x.md"
    30	  seed_index_path "$_repo" "RELAY-SYSTEM/y.md"
    31	}
    32	
    33	echo "find-harness (GH-70 Phase 2):"
    34	[ -x "$FH" ] || { echo "  FAIL: locator not executable at $FH"; exit 1; }
    35	
    36	# GH-563 shakedown: the skill's mandatory first command used to be
    37	# `bash skills/1-hourly/relay-xyz/find-harness.sh --check`. It resolved against the caller's CWD and failed
    38	# in every installed/foreign-CWD scenario. Pin the installed-root discovery before exercising the
    39	# locator itself, so the documentation cannot reintroduce a path bug while this script stays green.
    40	ok "skill front door searches the user install root" \
    41	  "grep -q '\$HOME/.claude/skills/relay-xyz/find-harness.sh' '$SKILL'"
    42	ok "skill front door does not prescribe the CWD-relative command" \
    43	  "! grep -q '^bash skills/1-hourly/relay-xyz/find-harness.sh --check$' '$SKILL'"
    44	
    45	# --- Case 1: from the harness clone itself → resolves to self, NO concurrency warning, exit 0 ---

## F. test/path-integrity.sh @ 5212dae4, Check B (lines 46-140)
    46	# Scanned surface: every tracked *.sh + a curated set of operational docs (the
    47	# files that hand an operator a runnable path). The prefix list is intentionally
    48	# scoped to the relay/tooling surface to keep the signal high; extend `prefixes`
    49	# and `docs` when a new top-level tooling dir or operator doc appears.
    50	docs="README.md \
    51	relay-automation/README.md \
    52	skills/1-hourly/relay-automation/SKILL.md \
    53	skills/1-hourly/relay-xyz/SKILL.md"
    54	
    55	shfiles=()
    56	# The portable PDDA runtime describes target-only paths and historical layouts.
    57	# Preserve its existing exclusion from this repo-root token scanner; the installed
    58	# payload/startup contract is checked by the PDDA installer/governance suites.
    59	# Forge owns the source now; this exclusion is about path context, not ownership.
    60	while IFS= read -r p; do
    61	  case "$p" in utils/pdda/*) continue ;; esac
    62	  shfiles+=("$p")
    63	done < <(cd "$ROOT" && git ls-files '*.sh')
    64	
    65	# A path-like token must (a) start with a known tooling prefix, (b) contain no
    66	# glob/var/placeholder char (the [A-Za-z0-9._/-] class excludes * ? $ < > { } ` ),
    67	# and (c) end in a real extension — so globs (relay-automation/*.sh) and
    68	# placeholders (relay-system/<date>/<slug>.md) are skipped by construction.
    69	ext_re='(relay-automation|test|skill|skills|bin)/[A-Za-z0-9._/-]+\.(sh|md|tar\.gz)'
    70	# GH-744: repo skills live at skills/<tier>/<name>; an APP-DISCOVERY path (~/.claude/skills/<name>/...,
    71	# ~/.codex/skills/..., ~/.gemini/{config,antigravity,antigravity-cli}/skills/..., ~/.zcode/skills/...)
    72	# names the flat installed layout, which never exists in this tree. Blank those before tokenizing so
    73	# the bare `skills/<name>/...` tail is not mistaken for a repo path.
    74	app_root_re='s#(\.claude|\.codex|\.agents|\.zcode|config|antigravity|antigravity-cli)/skills/[A-Za-z0-9._/-]+##g'
    75	
    76	# Intentional FIXTURE LITERALS — path-like tokens that are test DATA (a file a test creates in a
    77	# throwaway temp repo at runtime), NOT references to a real file in this tree. Check B must skip them,
    78	# otherwise it false-positives on a case-sensitive filesystem: e.g. test/swarm-preflight.sh T22a asserts
    79	# case-INSENSITIVE shim classification using `relay-automation/Codex-turn.sh` (a deliberate case-variant
    80	# of the real lowercase codex-turn.sh). That literal resolves on case-insensitive macOS but not on
    81	# case-sensitive Linux, so scanning it made `validate.sh` green on macOS and red on Linux. Skipping it
    82	# keeps Check B FS-portable without weakening it for genuine references (the capital-C file can never
    83	# exist in this tree — the real shim is lowercase — so this can never mask a real path break). See #80.
    84	# Space-delimited; a token matches only when flanked by spaces (exact-token match, no substring slip).
    85	# GH-85: test/marathon-plan.sh creates `$J/test/gh-951-genuine-test.sh` in a throwaway temp repo to
    86	# simulate the "tests-reference-slug" partial signal — a fixture literal, not a real reference.
    87	# GH-63: test/signal-triage.sh passes `test/foo.sh` / `test/some-test.sh` as synthetic `--test` inputs
    88	# to exercise the classifier (they name no real file) — same class, skip them.
    89	# GH-108/GH-126/GH-127: test/swarm-preflight.sh's T35/T36 fixtures create test/bare-redirect.sh,
    90	# test/no-touch.sh, and test/comment-only.sh in a throwaway temp repo to exercise the genuine-ref
    91	# and bare-`>` fs-touching detectors — fixture literals, not references to files in this tree.
    92	# GH-321: test/gh308-frozen-twin-guard.sh feeds `relay-automation/codex-turnn.sh` to the frozen-twin
    93	# guard to prove a TYPO'd path in a `Frozen-twin-exception:` trailer fails loudly instead of silently
    94	# covering nothing. The token is deliberately a path that does not resolve — that IS the test input —
    95	# and it can never exist in this tree, so skipping it cannot mask a real path break.
    96	# GH-400: test/gh400-acceptance-fidelity.sh reproduces rebalance-OS issue #202 and its capture doc
    97	# VERBATIM as the fixture that pins the measured inversion. Both texts name `test/clio-exporter.sh`,
    98	# a file in THAT repo. Paraphrasing it to satisfy this check would defeat the fixture's whole point —
    99	# the test exists to prove a byte-for-byte comparison catches a real drift — and the path can never
   100	# exist in this tree, so skipping it cannot mask a real path break.
   101	# GH-660: test/gh660-skill-drift.sh builds a THROWAWAY canonical tree (skills/alpha|beta|gamma/
   102	# SKILL.md under a mktemp root) to exercise the drift guard — fixture literals, not references to
   103	# files in this tree; these names can never exist under the real skills/ (the real skills are named
   104	# per-skill, not demo-greek), so skipping them cannot mask a real path break.
   105	# GH-419 (added 2026-08-07, during the Litmus marathon): test/gh419-gate-inventory.sh writes its
   106	# fixtures to "$FIXTURE/test/<name>.sh" under a mktemp root and then asserts on the inventory KEYS
   107	# the tool returns, which are repo-relative by construction. The bare "test/safe.sh" strings in the
   108	# assertions are therefore inventory keys, not references to files in this tree — they can never
   109	# exist here, so skipping them cannot mask a real path break. Same shape as the six fixture names
   110	# already listed above.
   111	#
   112	# This entry is why the gh419 lane escalated on its first attempt: the fix belongs in THIS file,
   113	# which is not in that lane's artifact allowlist, so the builder could not have made it — an
   114	# off-lane edit would have been reverted as a containment violation. Recorded because a lane that
   115	# cannot pass its own gate is a plan defect, not a builder defect.
   116	# GH-509 (added 2026-08-12): test/ci-route.sh builds a throwaway git repo under $WORK and runs a real
   117	# `git mv test/old-regression.sh test/new-regression.sh` in it, to prove that a RENAMED regression
   118	# test still selects the full CI gate. The rename must be real: the defect being pinned is that
   119	# `git diff --name-only` reports only a rename's DESTINATION, so the source path never reaches
   120	# ci-route.sh's fail-closed branch, and no amount of hand-written path strings reproduces that —
   121	# only git does. Both names exist solely inside that temp repo and can never exist in this tree, so
   122	# skipping them cannot mask a real path break.
   123	# GH-551 (added 2026-08-14): the new-Bash guard's cases 15-20 create throwaway .sh files in the same
   124	# mktemp fixture repo the GH-321 cases use (`some-shim.sh` is the trailer example in the usage
   125	# comment). All are fixture literals that must never exist in this tree — that is what the guard
   126	# blocks — so skipping them cannot mask a real path break.
   127	# Ballast (added 2026-08-17): test/ballast-release.sh's --mutate-evidence builds a compliant fixture
   128	# manifest member entirely under a mktemp root (`$FIX/test/fixture-gate.sh`,
   129	# `$FIX/test/baselines/fixture-control.md`) so the negative control is discriminating rather than
   130	# always-red. Both names exist solely inside that scratch fixture and can never exist in this tree.
   131	# GH-267 (added 2026-08-27): test/gh267-express-skill.sh builds its whole fixture repo under a
   132	# mktemp root — its `test/gh999-*.sh` suites, unregistered sibling
   133	# (`test/gh999b-unreg.sh`), and new-Bash refusal probe (`relay-automation/new-thing.sh`) are
   134	# files the DRIVER's check verdicts are asserted against inside that temp repo. They exist
   135	# solely there and can never exist in this tree, so skipping them cannot mask a real path break.
   136	# GH-592 (added 2026-09-13): the same fixture repo names sibling suites `test/gh997-demo.sh` /
   137	# `test/gh998-demo.sh` (resume cases for issues 997/998) and `test/other.sh` (the wrong-suite
   138	# negative receipt) — fixture literals of the same class, never files in this tree. Likewise
   139	# test/gh425-gate-provenance-pr.sh's synthetic express receipts name `test/gh592-demo.sh` /
   140	# `test/gh590-demo.sh` as the suite `command` under a mktemp root.

## G. other SKILL.md readers @ 5212dae4
### test/gh278-turn-timeout-parity.sh:55-66
    55	[[ "$sh_default" == "$EXPECTED" ]] \
    56	  && ok "Bash default is ${EXPECTED}s" \
    57	  || bad "Bash default must be ${EXPECTED}s, got [${sh_default:-missing}]"
    58	
    59	# The operator-facing skill must describe that same Aider default, rather than merely mention a cap.
    60	if grep -Fq 'Aider default: 900s in both runtime shims' "$SKILL"; then
    61	  ok "relay-xyz documents the shared ${EXPECTED}s Aider default"
    62	else
    63	  bad "relay-xyz must document the shared ${EXPECTED}s Aider default"
    64	fi
    65	
    66	# ── Behavioural: a timeout-killed turn must not leave 0-byte stubs behind ──────────────────
### test/gh346-gateway-allowlists.sh:398-406
   398	fi
   399	
   400	# 2.8 — the worker table must document deepseek, the gateway this issue's own list forgot
   401	if grep -qi "deepseek" "$ROOT/skills/1-hourly/relay-xyz/SKILL.md"; then
   402	  pass "2.8 relay-xyz SKILL.md documents the deepseek worker"
   403	else
   404	  fail "2.8 relay-xyz SKILL.md still omits deepseek — the original discovery gap"
   405	fi
   406	
### test/gh681-reviewer-probe-rules.sh:92-102
    92	
    93	# --- Case 6: drift guard — every place the rule is codified still carries it ---------------------
    94	for f in skills/1-hourly/relay-xyz/SKILL.md skills/1-hourly/relay/SKILL.md utils/py/marathon_drive.py; do
    95	  grep -qF "Declined — unproven generalization" "$ROOT/$f" \
    96	    && pass "case 6: $f carries the generalization rule" \
    97	    || fail "case 6: $f lost the generalization rule (GH-681 codified it in two-plus places)"
    98	done
    99	grep -qF "MAY run narrow, non-mutating probes" "$ROOT/skills/1-hourly/relay-xyz/SKILL.md" \
   100	  && pass "case 6: skills/1-hourly/relay-xyz/SKILL.md carries the probe allowance" \
   101	  || fail "case 6: skills/1-hourly/relay-xyz/SKILL.md lost the probe allowance"
   102	

## H. utils/ci-route.sh @ 5212dae4 lines 54-70 and 316-345
    54	# Docs surfaces: route=docs and tier 1 when nothing else is touched (GH-509, widened by GH-35 and
    55	# GH-487). GH-831 D4 adds skill files and the ledger. Precedence, in order:
    56	#   1. text, evidence and governance paths, as before (skills/**/SKILL.md lands here via *.md);
    57	#   2. the ledger/data dumps and their generated views — docs even though subsystem_of() claims
    58	#      releases.db/.sql, so a ledger-only push qualifies through the Small run;
    59	#   3. the non-text files of core skills (relay, relay-xyz, relay-automation, merge-cleanup, express,
    60	#      jog) are NOT docs; their markdown is, by rule 1, as before — the full-gate list below still
    61	#      catches every relay-xyz and relay-automation file;
    62	#   4. any other skills/** path is docs unless subsystem_of() claims it for an area.
    63	is_docs_surface() {
    64	  case "$1" in
    65	    *.md|*.txt|PROJECT/*|docs/*|relay-system/*|decisions/*|.pdda-*|.xyz-launch-artifact|TESTS-RESULTS/*) return 0 ;;
    66	    releases.db|releases.sql|harnesses.db|harnesses.sql|LEADERBOARD.html|RELEASES-PREVIEW.html) return 0 ;;
    67	    skills/*/relay/*|skills/*/relay-xyz/*|skills/*/relay-automation/*|skills/*/merge-cleanup/*|skills/*/express/*|skills/*/jog/*) return 1 ;;
    68	    skills/*) [ -z "$(subsystem_of "$1" || true)" ] ;;
    69	    *) return 1 ;;
    70	  esac
   316	  else
   317	    docs_only=false
   318	  fi
   319	
   320	  # These surfaces own the coordination kernel, containment boundary, frozen twins,
   321	  # worktree safety, or CI gate itself. They require the full suite before merge.
   322	  # (GH-35 moved utils/pdda/** and skills/*/agent-chorus code off this list and into the
   323	  # subsystem registry, per the issue's Tier-2 mapping; their focused suites run instead.)
   324	  case "$path" in
   325	    validate.sh)
   326	      if ! is_validate_append_only; then
   327	        full_required=true
   328	      fi
   329	      ;;
   330	    .github/workflows/*|utils/ci-route.sh|test/ci-route.sh|test/ci-workflow.sh)
   331	      full_required=true
   332	      ;;
   333	    # GH-836 D1: gh436-merge-cleanup left Small for Large. These are its only docs inputs (the worktree
   334	    # safety contract and merge-cleanup's SKILL.md, which its parity guard reads), so a landing that
   335	    # touches either takes the full registry, and gh436 still checks every change to what it reads.
   336	    WORKTREE-SAFETY.md|skills/*/merge-cleanup/SKILL.md)
   337	      full_required=true
   338	      ;;
   339	    bin/tick|bin/validate-relay-block|src/*)
   340	      full_required=true
   341	      ;;
   342	    relay-automation/*|skills/*/relay-automation/*|skills/*/relay-xyz/*)
   343	      full_required=true
   344	      ;;
   345	    utils/py/*)

## I. validate.sh TESTS registrations
135:  "gh278-turn-timeout-parity.sh" # GH-278 (Aider Python/Bash/doc timeout default must stay aligned)
157:  "gh346-gateway-allowlists.sh" # GH-346 Phase 2 (every agent-id allowlist agrees on the shipped gateway set)
527:  "path-integrity.sh"
549:  "gh678-installer-live-links.sh" # GH-678 (no installer replaces a live symlink it does not own; dangling still cleaned; sandboxed HOME)
562:  "find-harness.sh"
620:  "gh681-reviewer-probe-rules.sh"     # GH-681 (reviewer prompt allows narrow non-mutating probes with one role-consistent verification clause; scaffold + mirrors carry the generalization/falsifier rule; scratch sanctioned, .pytest_cache residue still off-lane)

## J. AGENTS.md @ 5212dae4 lines 140-150 (No new tests)
   140	- **No new tests (GH-831, operator decision 2026-09-25).** This covers three things:
   141	  - Do not add a new `test/` suite or a new entry in `validate.sh`'s `TESTS` registry.
   142	  - Do not add new gate machinery: guards, lanes, runners or telemetry stages.
   143	  - Do not add a test to enforce this rule.
   144	
   145	  Verify a change with the existing suite that covers it, or with a manual check recorded under
   146	  `TESTS-RESULTS/<date>+GH-<n>/` with its `provenance.jsonl`. Edit an existing suite only to keep it truthful
   147	  when the behaviour it pins changes. A red control (see *Verified beats plausible*) is witnessed on an  [Unverified — no citation]
   148	  existing suite or recorded as a manual check. Reviewers treat a new test file as a finding.
   149	
   150	  The gate is being cut to Small/Medium/Large tiers under [#831](https://github.com/HiQS-Labs/XYZ-forge/issues/831).

## K. Mac Mini deployed Skills Army HQ SKILL.md (GH-672 SOP), lines 39-82
    39	
    40	## SOP: one deployed collection per device (GH-672)
    41	
    42	**Canonical owning repo → Git Pulse Sync `Deployed Skills/` → app directory symlinks.**
    43	Every device uses its own Pulse checkout's `Deployed Skills` directly. Do not import those
    44	payloads into a second `~/Documents/Deployed Skills` collection. This SOP supersedes the
    45	GH-508 spike and the former GH-536 secondary-device copy procedure. The owning repository
    46	remains the only authoring source; Pulse and Skills Army mini are generated distributions.
    47	This entire bundle, including this SOP and recovery guidance, travels with the projection.
    48	
    49	1. **Publish from source.** Change the skill in its owning repo and land it there first.
    50	   On the designated publisher, preview then apply `intake.py update NAME --source
    51	   /path/to/owning-repo/skills/<tier>/NAME` (or `add` for a new skill) against the Pulse root.
    52	   Commit the reviewed portable paths immediately; the Pulse writer cannot rebase a dirty
    53	   tracked tree. Push through the existing Pulse workflow. Do not edit deployed payloads.
    54	2. **Prepare each device's checkout.** Pull the Pulse checkout when its tracked tree is clean.
    55	   Before any local initialization, verify the collection's tracked `.gitignore` excludes
    56	   receipts, pending receipts, targets, catalog, history, locks, backups, staging and caches
    57	   as listed in [recovery.md](references/recovery.md). Ignoring an already tracked file is
    58	   insufficient: the publisher must untrack machine state while retaining its local copy.
    59	3. **Adopt in place once.** For a pulled collection without local receipts, preview then apply:
    60	   `python3 "$HOME/git-pulse-sync/Deployed Skills/intake.py" init --adopt-existing`, then
    61	   the same command with `--apply` before `init`. This validates the clean Git-carried payloads
    62	   and creates only local state, with targets disabled; it makes no second payload copy.
    63	   Plain `init` is only for a new empty collection. Existing initialized collections keep
    64	   their identity; never copy another device's receipts or hand-edit their root.
    65	4. **Deploy local links.** Configure only this device's chosen targets, preview sync, apply,
    66	   and verify links resolve directly into its Pulse collection. Verify app discovery
    67	   separately. The initial defaults stay disabled until the operator selects targets.
    68	5. **Refresh.** Pull published changes into the clean Pulse checkout. Existing app symlinks
    69	   read the updated bytes immediately; refresh app discovery as needed. Preview/apply
    70	   `catalog` for newly arrived skills and sync for link additions. For an intentionally
    71	   removed upstream skill, explicitly `remove NAME` to acknowledge its absent payload,
    72	   then sync to withdraw owned links. Do not re-import the collection into itself.
    73	
    74	Use a single designated publisher for portable payload changes; other devices pull and
    75	write only their ignored local deployment state. Configure `--canonical`, `XYZ_FORGE_ROOT`,
    76	or the local `targets.json` canonical path when the Forge drift checker is available;
    77	its absence must be reported, not mistaken for a successful canonical-source check.
    78	Git tracks only executable file-mode bits, so compare digests against the local checkout.
    79	For an existing second collection, use [recovery.md](references/recovery.md)'s migration
    80	procedure; preserve local improvements in their owning repos before retiring any copy.
    81	
    82	## Conversational workflow

## L. Mac Mini deployed intake.py: parser + update path
   620	
   621	
   622	def parser():
   623	    p = argparse.ArgumentParser(description=__doc__)
   624	    p.add_argument("--root", default=default_root(),
   625	                   help="Collection root (env: XYZ_SKILLS_ROOT)")
   626	    p.add_argument("--apply", action="store_true", help="Apply the requested mutation; default is preview")
   627	    p.add_argument("--dry-run", action="store_true", help="Write nothing")
   628	    sub = p.add_subparsers(dest="command", required=True)
   629	    init = sub.add_parser("init")
   630	    init.add_argument("--adopt-existing", action="store_true", help="Attach local state to a clean Pulse collection in place")
   631	    sub.add_parser("activate-manager", help="Switch legacy collection entry links to the installed Skills Army HQ")
   632	    add = sub.add_parser("add"); add.add_argument("source")
   633	    update = sub.add_parser("update"); update.add_argument("name"); update.add_argument("--source")
   634	    remove = sub.add_parser("remove"); remove.add_argument("name"); remove.add_argument("--allow-empty", action="store_true")
   635	    for verb in ("list", "catalog", "recover"):
   636	        sub.add_parser(verb)
   637	    target = sub.add_parser("targets")
   638	    target.add_argument("--id"); target.add_argument("--path")
   639	    target.add_argument("--consumer", action="append", default=[])
   640	    target.add_argument("--disable", action="store_true"); target.add_argument("--remove", action="store_true")
   641	    note = sub.add_parser("prerequisite"); note.add_argument("name"); note.add_argument("text")
   642	    return p
   643	
   644	
   645	def main(argv=None):
   646	    args = parser().parse_args(argv)
   647	    try:
   648	        root = location(args.root)
   649	        apply = args.apply and not args.dry_run
   650	        if args.command == "init":
   651	            if args.adopt_existing:
   652	                adopt_existing(root, apply)
   653	                return 0
   654	            source = Path(__file__).resolve().parent.parent
   655	            info, ignored = package_info(source)
   656	            require((source / "scripts" / "sync.py").is_file(), "Manager is incomplete: missing scripts/sync.py")
   657	            initial_digest = digest(source, ignored)
   658	            require(not within(root, source) and not within(source, root) and root != source, "Source/collection overlap")
   659	            if (root / STATE).exists():
   660	                load(root)
   700	            if args.command == "activate-manager":
   701	                require("skills-army-hq" in found, "Import skills-army-hq before activation")
   702	                require(found["skills-army-hq"]["digest"] == state["skills"]["skills-army-hq"]["digest"],
   703	                        "Manager differs from imported receipt")
   704	                for name in ("intake.py", "sync.py"):
   705	                    require((root / "skills-army-hq" / "scripts" / name).is_file(), "Incomplete manager")
   706	                    actions.append({"kind": "link", "root": str(root), "name": name,
   707	                                    "before": os.readlink(root / name), "after": f"skills-army-hq/scripts/{name}"})
   708	                details = {"manager": "skills-army-hq", "actions": actions}
   709	            elif args.command in ("add", "update"):
   710	                raw = args.source if args.command == "add" else args.source or state["skills"].get(args.name, {}).get("source")
   711	                require(raw, "No source receipt; provide --source")
   712	                source, record, ignored = source_record(raw)
   713	                name = record["name"]
   714	                if args.command == "update":
   715	                    require(name == safe_name(args.name) and name in found, "Update name/source mismatch or absent skill")
   716	                require(not within(source, root) and not within(root, source) and source != root, "Source/collection overlap")
   717	                require(name not in found or args.command == "update", f"Skill already exists: {name}; use update")
   718	                before = found.get(name, {}).get("digest")
   719	                if before == record["digest"]:
   720	                    print(f"Unchanged: {name}"); return 0
   721	                details = {"name": name, "source": str(source), "before": before, "after": record["digest"], "commit": record["commit"]}
   722	                if apply:
   723	                    if before:
   724	                        details["backup"] = archive(root, root / name)
   725	                    actions.append(stage_payload(root, source, before, record["digest"], name, ignored))

## M. Mac Mini deployed sync.py: --status/--canonical
    33	def canonical_root(explicit, config, state):
    34	    """Resolve the XYZ-forge checkout whose skills/ is canonical for this collection.
    35	
    36	    Order: --canonical, XYZ_FORGE_ROOT, targets.json "canonical", then the repository the
    37	    manager itself was vendored from. An explicit setting that does not resolve is an error;
    38	    a stale provenance path is skipped. Returns (path, origin) or (None, None)."""
    39	    candidates = [("--canonical", explicit), ("XYZ_FORGE_ROOT", os.environ.get("XYZ_FORGE_ROOT")),
    40	                  ('targets.json "canonical"', config.get("canonical")),
    41	                  ("skills-army-hq provenance", state["skills"].get("skills-army-hq", {}).get("repository"))]
    42	    for origin, raw in candidates:
    43	        if not raw:
    44	            continue
    45	        path = Path(raw).expanduser()
    46	        if (path / CHECKER).is_file() and (path / "skills").is_dir():
    47	            return path.resolve(), origin
    48	        shared.require(origin == "skills-army-hq provenance",
    49	                       f"Canonical root from {origin} lacks {CHECKER} or skills/: {path}")
    50	    return None, None
    51	
    52	
    53	def drift_report(root, canonical):
    54	    """Ingest the forge checker's --json; exit 0/1 are both reports, anything else is a failure."""
    55	    run = subprocess.run([sys.executable, "-B", str(canonical / CHECKER), "--canonical", str(canonical),
    56	                          "--collection", str(root), "--json"], text=True, capture_output=True)
    57	    shared.require(run.returncode in (0, 1), f"skill_drift_check failed ({run.returncode}): {run.stderr.strip()}")
    58	    report = json.loads(run.stdout)
    59	    return {"canonical": str(canonical), "ok": [e["skill"] for e in report["ok"]],
    60	            "drifted": [{"skill": e["skill"], "vendored_path": e["vendored_path"], "canonical_path": e["canonical_path"]}
    61	                        for e in report["drifted"]],
    62	            "unrecognized": [e["skill"] for e in report["unrecognized"]]}
    63	
    64	
    65	def warn(warnings, message):
    66	    """Loud and immediate (stderr) so a refusal that follows still shows every finding."""
    67	    warnings.append(message)
    68	    print(f"skills-army-hq sync: WARN {message}", file=sys.stderr)
    69	
    70	
    71	def drift_gate(root, state, config, found, explicit, apply, allow_drift, warnings):
    72	    """WARN on every drifted forge-owned skill; REFUSE an apply that would deploy one."""
    73	    canonical, origin = canonical_root(explicit, config, state)
    74	    if canonical is None:
    75	        warn(warnings, "drift check skipped: no canonical XYZ-forge root resolved "
    76	                       "(set --canonical, XYZ_FORGE_ROOT, or targets.json \"canonical\")")
    77	        return None
    78	    drift = {**drift_report(root, canonical), "origin": origin}
    79	    drifted = [e for e in drift["drifted"] if e["skill"] in found]
    80	    for entry in drifted:
    81	        remedy = (f"python3 {shlex.quote(str(root / 'intake.py'))} --root {shlex.quote(str(root))} --apply "
    82	                  f"update {entry['skill']} --source {shlex.quote(str(Path(entry['canonical_path']).parent))}")
    83	        warn(warnings, f"DRIFTED {entry['skill']}: vendored {entry['vendored_path']} != canonical "
    84	                       f"{entry['canonical_path']} — re-vendor: {remedy}")
    85	    deploying = any(t["enabled"] for t in config["targets"])
    86	    if apply and drifted and deploying and not allow_drift:
    87	        names = ", ".join(e["skill"] for e in drifted)
    88	        shared.require(False, f"REFUSED: deploy would ship drifted vendored SKILL.md for {names}; "
    89	                              f"canonical is {canonical / 'skills'} — re-vendor from it (or --allow-drift, loudly)")
    90	    if apply and drifted and allow_drift:
    91	        warn(warnings, f"--allow-drift: deploying {len(drifted)} drifted skill(s) against canonical {canonical}")
    92	    return drift
   180	    p = argparse.ArgumentParser(description=__doc__)
   181	    p.add_argument("--root", default=shared.default_root(),
   182	                   help="Collection root (env: XYZ_SKILLS_ROOT)")
   183	    p.add_argument("--apply", action="store_true")
   184	    p.add_argument("--dry-run", action="store_true")
   185	    p.add_argument("--status", action="store_true", help="Read-only reconciliation report")
   186	    p.add_argument("--adopt", action="append", default=[], metavar="SKILL")
   187	    p.add_argument("--migrate", action="append", default=[], metavar="SKILL")
   188	    p.add_argument("--migrate-from", action="append", default=[], metavar="SKILL=LOCAL_SOURCE",
   189	                   help="Explicitly replace a selected alternative source link; preserve old link text")
   190	    p.add_argument("--retire-trinity", metavar="LOCAL_SOURCE", help="Withdraw only the known replaced skill")
   191	    p.add_argument("--archive-legacy", action="store_true", help="Explicitly archive a matching real legacy folder")
   192	    p.add_argument("--canonical", metavar="FORGE_ROOT",
   193	                   help="XYZ-forge checkout whose skills/ is canonical (else XYZ_FORGE_ROOT, targets.json \"canonical\")")
   194	    p.add_argument("--allow-drift", action="store_true",
   195	                   help="Deploy despite drifted vendored skills; the drift is still reported and recorded")
   196	    args = p.parse_args(argv)
   197	    try:
   198	        root = shared.location(args.root)
   199	        apply = args.apply and not args.dry_run and not args.status
   200	        for name in args.adopt + args.migrate:

## N. CHANGELOG.md @ 5212dae4 lines 123-128 (GH-881 publisher ruling)
   123	**Open issues on this arc:** the SOP still names one "designated publisher" machine. The operator ruled that
   124	any device may publish, and GH-881 tracks that rewording along with an amendment to GH-676. The
   125	codebase-memory skill is vendored from the unmerged `feat/committed-skill-file` branch of
   126	`codebase-memory-mcp`, which should land upstream. The gap that stranded codebase-memory (added
   127	locally, never committed to the transport) is the check GH-881 proposes.
   128	

## O. .github/workflows/wave-reconcile.yml triggers (lines 1-12) and ci.yml canary (243-252)
     1	name: Wave reconciliation
     2	
     3	on:
     4	  pull_request:
     5	    types: [closed]
     6	    branches: [development]
     7	  workflow_dispatch:
     8	  # Recover missed close events from committed lifecycle state, including queue overflow.
     9	  schedule:
    10	    - cron: '23 */6 * * *'
    11	
    12	concurrency:
   243	  canary-ubuntu:
   244	    name: portability canary (ubuntu — advisory, never breakage)
   245	    # GH-347: integration-time signal, not PR feedback. A development push is the last recurring
   246	    # point before promotion where this drift can be acted on; workflow_dispatch is the deliberate
   247	    # fallback. Push-to-main is after the promotion decision, and pull_request was the 8m54s long pole.
   248	    if: >-
   249	      (github.event_name == 'push' && github.ref == 'refs/heads/development') ||
   250	      github.event_name == 'workflow_dispatch'
   251	    runs-on: ubuntu-latest
   252	    continue-on-error: true

## P. Observed on the Mac Mini 2026-10-02 ~6:50–7:40 PM PT (read-only)
- readlink of ~/.claude, ~/.agents, ~/.gemini/config, ~/.zcode, ~/.grok-bot skills/relay-xyz →
  /Users/noelsaw/Documents/GitHub/rebalance-git-pulse/Deployed Skills/relay-xyz. ~/.codex/skills exists
  but has no relay-xyz; ~/.gemini/antigravity/skills and ~/.gemini/antigravity-cli/skills absent.
- sync.py --root "<that>/Deployed Skills" --status → errors [], warnings ["drift check skipped: no canonical ..."].
- .deploy-skills.json relay-xyz receipt: source = the collection's own relay-xyz folder, repository =
  rebalance-git-pulse, commit 1636d8df, prerequisites [].
- Mini XYZ-forge clone: development [ahead 7, behind 172] (cached @{u}); no ~/.config/xyz/harness.
- macOS 27.0: readlink -f works.
````
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

- [Should] In A, Post-merge deployment checklist step 3, `Unchanged: relay-xyz` says “stop.” The quoted `intake.py:719-720` returns before generating preview digests when the source and deployed digests already match. Stopping the checklist there skips the required Mini verification and #938 evidence/closure in steps 4 and 7. Change this to “skip apply/commit, identify the existing Pulse publish commit, then continue the device checks”; if the existing publish commit cannot be identified, record that explicitly rather than claiming the publish step succeeded.
  Observed input: A step 3's preview of an already-published `relay-xyz`; L `intake.py:719-720` has `if before == record["digest"]: print(f"Unchanged: {name}"); return 0`.
  Affected scope: A publisher whose collection already has the canonical `relay-xyz` digest, including a resumed deployment.
  Falsifier: A preview where `before != record["digest"]` should still proceed to apply, digest verification, and a new Pulse commit; an already-published case should still reach the Mini checks.
- [Pass] The draft B directs a managed `Deployed Skills/relay-xyz` link past `install.sh` to the installed locator and preserves the existing install path for an absent or dangling link. The existing locator code at C:93-110 contains `$HOME/.claude/skills/relay-xyz/find-harness.sh`, satisfying the pin quoted at E:40-43; the draft adds no nonexistent repo-path token under F:65-74.
- [Pass] A's one-phase plan defers installer behavior, adds no suite, and selects the full gate. This agrees with J:140-148 and H:342-343. The 40/35/50/85 rationale is proportionate to the documented local impact and one-section edit in A, Rating. The checklist covers the requested CI, reconciliation, publisher, Mini, Studio, rollback, and close-after-Mini steps at A, Post-merge deployment checklist steps 1-7.
- [Pass] The quoted `intake.py` parser puts `--root` and `--apply` before `update` (L:622-633), and the quoted `sync.py` parser accepts `--status` and `--canonical` (M:180-199). Local read-only probe `gh run list --help | grep -nE -- '--commit|--workflow|--repo'` exited 0 and printed `--commit SHA`, `--workflow string`, and `--repo [HOST/]OWNER/REPO`; `gh pr view --help` similarly printed `--json fields` and `--repo` (exit 0). This supports the checklist flag shapes; the commands were not run against GitHub.

VERDICT: FAIL
Basis: The plan and draft satisfy the main scope, but the `Unchanged` path can terminate the deployment checklist before its required Mini evidence and issue closure.

### Producer · Round 2 (claude-a)

Dispositions for Round 1 findings:
- [Should] `Unchanged: relay-xyz` stops the checklist — **Implemented** (plan commit `e3561387`, rewrap
  `4768d983` + local rewrap, branch fix/gh938-relay-xyz-managed-setup). Step 3 now: record the prior
  receipt first; on `Unchanged` skip apply/commit, identify the existing Pulse publish commit with
  `git -C <pulse> log -1 --format=%H -- "Deployed Skills/relay-xyz"` (message must name `<sha>`/the PR;
  otherwise record that on #938 instead of claiming a publish) and **continue at step 4**. Your
  falsifier holds: `before != digest` still proceeds to apply → verify → commit.
- [Unverified — no citation] ×3 — no change needed.

New work found while fixing (self-reported, please check):
- Rollback (step 6) previously re-published from the pre-merge XYZ-forge commit. The operator asked for
  "intake update back to prior receipt commit". It now uses the prior receipt recorded in step 3.
  Grounding: deployed `intake.py` `source_record()` (lines 200-207 of the Mini copy) does
  `git rev-parse --show-toplevel` on the source and refuses with "Source must be in a local Git
  repository", so an exported/archived folder would be refused. The rollback therefore checks the prior
  payload out in a temporary **Git clone** (`git clone <pulse> <tmp> && git -C <tmp> checkout <prior commit>`,
  source `"<tmp>/Deployed Skills/relay-xyz"`; or an XYZ-forge clone at the prior commit), and requires
  the apply's `after` digest to equal the recorded prior `digest`.

Revised step 3 (through the Apply bullet) and step 6, verbatim from the branch:

```text
3. **Publish (on the publisher).**
   - Record the prior receipt first (rollback anchor): `python3 "$C/intake.py" --root "$C" list` →
     note relay-xyz's `digest`, `repository` and `commit` (on the Mini today: `rebalance-git-pulse`
     @ `1636d8df`).
   - Preview: `python3 "$C/intake.py" --root "$C" update relay-xyz --source
     "<clone>/skills/1-hourly/relay-xyz"`. Expect `before`/`after` digests and `commit` = `<clone>`
     HEAD. `--source` is required: the Mini's receipt records the collection itself as source, which
     `intake.py` refuses (overlap). If it prints `Unchanged: relay-xyz`, the payload is already
     published: skip apply and commit, find the existing publish commit with
     `git -C <pulse> log -1 --format=%H -- "Deployed Skills/relay-xyz"` (confirm its message names
     `<sha>` or this PR; if it cannot be identified, record that on #938 instead of claiming a
     publish), and continue at step 4.
   - Apply: the same command with `--apply` before `update`. It writes a verified backup ZIP under

6. **Rollback (if a check fails after publish).** On the publisher, `intake.py` update back to the
   prior receipt recorded in step 3. Check out that payload in a temporary Git clone outside `$C`
   (`intake.py` requires the source to sit inside a local Git repository): if the prior receipt's
   repository is the Pulse repo, `git clone <pulse> <tmp> && git -C <tmp> checkout <prior commit>`
   and use `--source "<tmp>/Deployed Skills/relay-xyz"`; if it is XYZ-forge,
   `git clone https://github.com/HiQS-Labs/XYZ-forge.git <tmp> && git -C <tmp> checkout <prior commit>`
   and use `--source "<tmp>/skills/1-hourly/relay-xyz"`. Preview, then `--apply`; the resulting
   `after` digest must equal the recorded prior `digest`. Commit and push as in step 3; devices pull
   and re-run step 4.
   (Alternatives in Skills Army HQ `references/recovery.md`: the verified backup ZIP or the staged
   prior folder.) If the doc itself is wrong, revert the PR on `development` through the normal lane.
```

Excerpt: deployed intake.py (Mac Mini copy) lines 196-207:

```python
def digest(folder, ignored=()):
    return hashlib.sha256(json.dumps(snapshot(folder, ignored), sort_keys=True).encode()).hexdigest()


def source_record(raw):
    source = Path(raw).expanduser().resolve(strict=True)
    info, ignored = package_info(source)
    result = subprocess.run(["git", "--no-optional-locks", "-C", str(source), "rev-parse", "--show-toplevel"],
                            text=True, capture_output=True)
    require(result.returncode == 0, f"Source must be in a local Git repository: {source}")
    repo = Path(result.stdout.strip()).resolve()
    require(within(source, repo) or source == repo and ignored,
```

Ask for Reviewer (Round 2): confirm the step-3 `Unchanged` branch and the step-6 rollback are correct
against the quoted `intake.py` (update path L:700-725 and `source_record` above) and that nothing else
in the plan, draft section, or checklist needs a change; set STATUS Approved if so.

handing off to Reviewer (codex) — take your turn.

### Reviewer · Round 2

swept file: yes

- [Pass] The revised step 3 handles the already-published case without stopping deployment verification: it says to skip apply and commit, inspect the existing Pulse publish commit, and "continue at step 4" (Producer Round 2, revised step 3). The quoted `intake.py:719-721` confirms why this branch needs separate handling: `Unchanged: relay-xyz` returns before preview details exist. A changed digest still follows the preview, apply, and receipt checks in A, checklist step 3.
- [Pass] The revised rollback uses the recorded prior receipt (`digest`, `repository`, `commit`) and a source inside a temporary Git clone, then requires the resulting `after` digest to match that prior digest (Producer Round 2, revised steps 3 and 6). The quoted `source_record()` excerpt requires a local Git repository, and `intake.py:710-725` accepts the explicit `--source`, checks collection overlap, and records the replacement digest. The actual post-merge rollback remains unexecuted in this plan review.
- [Pass] The whole packet's scope and checklist remain aligned with the operator requirements: B routes a managed `Deployed Skills/relay-xyz` link past `install.sh` and keeps the ordinary install path; C:93-110 and E:40-43 support the locator pin; H:342-343 supports the full gate; A, checklist steps 1-7 retain hosted CI, reconciliation, one publisher, Mini and Studio checks, rollback, and closure only after the Mini check. No further finding in the pre-existing portions of the embedded plan or draft.

VERDICT: PASS
Basis: The Round 1 `Unchanged` gap is resolved, and the receipt-based rollback is consistent with the quoted `intake.py` paths. Approval is for the plan and draft; implementation, gate evidence, and post-merge deployment remain future checklist work.

relay closed (Approved), no further turn needed.

### Producer · Round 3 (claude-a)

Dispositions for Round 2: all three Round 2 findings were passes and the verdict was PASS — no change
to the plan, draft section, or checklist since Round 2 (branch fix/gh938-relay-xyz-managed-setup; the
only later commit `449ee540` rewraps one line of checklist step 6, no wording change).

Process note: relay-drive REFUSED to attest the Round 2 `STATUS: Approved` with reason
`review-body-rewritten` (first divergence at byte 76752). Cause is on the Producer side, not the
review: the Round 2 Producer block ended with an extra blank line before the next-turn marker, and the
Reviewer block was inserted one newline earlier, so the pre-turn prefix no longer matched byte for byte.
The Round 2 token was spent (`done`), so this round is driven on a fresh token
`RELAY-gh938-plan-qa-r3` with `--reviewer codex`.

Ask for Reviewer (Round 3): re-confirm the Round 2 verdict against the same packet (no new content)
and, if it still holds, append your review block directly above the marker without editing anything
above it, and set STATUS Approved.

handing off to Reviewer (codex) — take your turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
