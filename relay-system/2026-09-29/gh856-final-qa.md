# RELAY · GH-856 locator final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-29.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(gh-856-locator-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-856-RELAY-LOCATOR.md`, `skills/1-hourly/relay-xyz/find-harness.sh`, `skills/1-hourly/relay-xyz/SKILL.md`, `skills/1-hourly/relay-xyz/install.sh`, and `test/find-harness.sh`. Compare the committed branch against origin/development; issue #856 is https://github.com/HiQS-Labs/XYZ-forge/issues/856.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-29
- Definition of Done: the copied skill resolves the canonical XYZ-forge clone from the seven bounded roots or a per-Mac config while preserving override, vendored, git-root, and self precedence; search rejects task clones and wrong origins, reports ambiguity and attempted locations; shared lock helpers load from the selected harness; `--check` warns on cached upstream lag, branch, held lock, and vendored drift without fetching, and prints an executable config-save hint. Bash 3.2 and existing suites remain green. No new suite or registry entry. The RELEASES row for #856 has the rated `86/82/50/55` and accepted start, with appeal neutral as the user supplied no appeal score.

### Review questions and evidence

1. Read the entire touched locator and test files, not only the added lines. Is any concrete #856 acceptance case unfulfilled or contradicted by the current code? Cite an observed input and line for any finding.
2. Does the implementation match the approved plan without duplicating the shared resolver or changing #394/#395/#396 behavior? Is the `--check` config command executable for paths containing spaces?
3. Do the copied-skill fixtures actually exercise the desired outputs, including seven roots, ambiguity, origin validation, lock, lag, and vendored drift? Identify a vacuous or missing assertion only with a concrete falsifier.
4. Is the plan/ledger/changelog state truthful, and has any new test file or registry entry entered the diff? Check `git diff origin/development...HEAD`.

Focused evidence from a disposable full clone: `test/find-harness.sh` 47/47, `test/gh396-find-harness-roots.sh` 41/41, `test/gh292-worktree-vendored-discovery.sh` 7/7, `test/gh448-driver-lock-resolver.sh` 18/18. `pdda.sh frontmatter` and `roadmap-coverage` found 0 errors; `releases_app.py check` found 0 failures and 9 pre-existing warnings. The one full qualifying gate is reserved for the final approved commit. Do not run mutation-heavy suites in this valued task clone.

Operational envelope: a local Bash locator for one repository family across four Macs. Grade against #856 and the approved plan. Do not request a general registry, network discovery service, or unrelated root-resolution refactor. Review only; write findings to this relay file.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes — read the full locator, existing test, installer, skill, and GH-856 project doc, including pre-existing code in the touched files.

- [Blocker] `--check` calls a stale lock **currently HELD** and says a relay will block. `find-harness.sh:471-474` equates an existing directory with a live holder, while `relay_drive.py:523-547` reclaims a directory whose PID is dead. Read-only probe from this worktree: `XYZ_HARNESS=/Users/noelsaw/marathon-clones/xyz-gh856-relay-locator bash skills/1-hourly/relay-xyz/find-harness.sh --check` exited 0 and printed `a driver lock is currently HELD (.../.git/relay-driver.lock) — a relay started here will BLOCK until it frees`; `cat .../.git/relay-driver.lock/pid` returned `14444`, and `kill -0 14444` exited 1. Probe output was saved under `.relay-scratch/tmp/gh856-foreign-check.out` and `.relay-scratch/tmp/gh856-lock-state.out`. Fix the advisory to distinguish a live holder from a stale directory, and make the existing lock fixture at `test/find-harness.sh:227-243` exercise a live PID plus the stale case; its bare `mkdir` currently proves only directory presence.
  Observed input: selected harness `/Users/noelsaw/marathon-clones/xyz-gh856-relay-locator`; `.git/relay-driver.lock/pid` is `14444`, a non-running PID.
  Affected scope: non-vendored selected harnesses with an existing driver-lock directory, especially stale locks after a killed run.
  Falsifier: a directory containing a live holder PID must still print HELD; the observed dead-PID directory must report stale/reclaimable or avoid the held warning, matching the driver's decision.
- [Should] The copied-skill use case is contradicted by the skill's frontmatter and use guidance: `SKILL.md:9-13` and `:59-64` exclude repos without `relay-automation/`, while `:84-89` expressly says a copied deployment works from a foreign repo. Update the entry/use wording so an agent in the GH-856 foreign checkout can invoke the skill and let the locator select the harness. Concrete input: `test/find-harness.sh:120-143` places the copied skill under `Deployed Skills/relay-xyz` and runs it from `gh856-foreign`.
- [Should] The existing copied-skill fixture checks `--root` and `--check`, but never calls copied `--env` (`test/find-harness.sh:141-256`), although the acceptance in `GH-856-RELAY-LOCATOR.md:58` requires usable exports. It also never asserts the non-`development` warning, although `find-harness.sh:412-414` implements it. Add both assertions to this existing suite. Concrete falsifiers: removing `export TICK_REPO_ROOT` at `find-harness.sh:380`, or removing the branch warning at `:412-414`, should turn the corresponding fixture red; the current copied-fixture calls would not observe either output. [Unverified — needs clone run] for the mutation/red-control result.
- [Pass] The seven bounded paths in `find-harness.sh:123-131` match the project plan at `GH-856-RELAY-LOCATOR.md:50`, and the existing fixture iterates those paths at `test/find-harness.sh:145-186`. The RELEASES row has `86/82/50/55` and `in-progress` (`releases.sql:773`); the changelog records the GH-856 work (`CHANGELOG.md:3-5`).
- [Unverified — turn constraint] I did not run `git diff origin/development...HEAD` or the mutation-heavy suites: this reviewer turn explicitly forbids running git and test scripts. The reported disposable-clone focused results remain the only suite evidence here; changed-file/new-suite diff scope still needs the harness or Producer's independent check.

VERDICT: FAIL
Basis: The observed stale lock produces a false held/blocking warning, and the touched skill guidance and fixture leave the copied deployment contract incompletely stated and measured.

Handing off to Producer — go to the Producer window and say 'take your turn'.

### Producer · Round 2

- Implemented the [Blocker]: `--check` now reads the shared resolver's lock path, checks its PID for liveness, and distinguishes a live holder from a stale directory. The existing copied-skill fixture now writes the test process PID, then a reaped child PID, and asserts opposite advisories. `test/find-harness.sh` is 50/50 in disposable full clone `xyz-gh856-verify`.
- Implemented the first [Should]: the skill frontmatter and use guidance now allow starting in a foreign checkout when the locator can select the XYZ-forge harness.
- Implemented the second [Should]: the same copied-skill fixture executes `--env` exports and checks harness, repo root, and tick; it switches to a `topic` branch and asserts the non-`development` warning. The suite is 50/50 after these controls.
- Confirmed `test/gh396-find-harness-roots.sh` 41/41 and `test/gh448-driver-lock-resolver.sh` 18/18 after the lock change. `bash -n`, ShellCheck at error severity, and `git diff --check` passed. `git diff --name-only origin/development...HEAD` shows only the existing test file, three skill files, plan, relay threads, changelog, and canonical ledger outputs; no new suite or registry entry.
- The revised implementation and evidence are committed at `17c00562`. The single full qualifying gate remains for the approved revision.

Handing off to Reviewer — review the revised committed branch in round 2.

### Reviewer · Round 2

swept file: yes — read the entire locator, existing test, installer, skill, and GH-856 project doc, including pre-existing portions of the touched files. No other concrete acceptance defect was found in that sweep.

- [Pass] The stale-lock advisory now distinguishes a live PID from a dead or missing PID (`skills/1-hourly/relay-xyz/find-harness.sh:471-485`), using the selected harness's shared resolver loaded at `:267-273`. Read-only probe: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; XYZ_HARNESS="/Users/noelsaw/marathon-clones/xyz-gh856-relay-locator" bash skills/1-hourly/relay-xyz/find-harness.sh --check > "$TMPDIR/gh856-round2-check.out" 2>&1; rc=$?; printf 'rc=%s\n' "$rc"; rg -n 'driver lock|harness clone is|save this harness' "$TMPDIR/gh856-round2-check.out"` exited 0 and printed `rc=0` plus `stale driver lock (.../.git/relay-driver.lock, pid 31041) — the driver will try to reclaim it`. The existing fixture now checks both live and stale output (`test/find-harness.sh:237-261`).
- [Pass] The copied deployment guidance accepts a foreign checkout (`skills/1-hourly/relay-xyz/SKILL.md:9-13,59-60`); the locator retains override, vendored, git-root, and self precedence before config/search (`find-harness.sh:171-246`). The config hint is shell-quoted (`:402-408`) and the fixture executes it using a path with spaces (`test/find-harness.sh:145-147,205-217`). The seven bounded roots, wrong-origin rejection, ambiguity, lag, branch, and vendored-drift checks are present in the existing fixture (`test/find-harness.sh:145-203,222-268`). The project doc records focused disposable-clone results (`GH-856-RELAY-LOCATOR.md:71-76`), and the ledger row retains `86/82/50/55` with neutral appeal (`releases.sql:773`).
- [Should] The new `--env` fixture reports that tick is usable while never reading `$TICK`: it checks `$HARNESS`, `$TICK_REPO_ROOT`, and `$RELAY_HAS_TICK` only (`test/find-harness.sh:218-221`). Removing the actual `export TICK` line (`find-harness.sh:381`) would leave that assertion green. Strengthen this existing assertion to require the absolute, executable `$TICK` under the selected harness, then witness its red control in the disposable full clone. Narrow read-only probe of the current predicate: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; env -u TICK bash -c 'export HARNESS=/tmp/XYZ-forge TICK_REPO_ROOT=/tmp/XYZ-forge RELAY_HAS_TICK=1; test "$HARNESS" = "$1" && test "$TICK_REPO_ROOT" = "$1" && test "$RELAY_HAS_TICK" = 1; rc=$?; printf "rc=%s TICK=%s\n" "$rc" "${TICK-UNSET}"; exit "$rc"' _ /tmp/XYZ-forge` exited 0 with `rc=0 TICK=UNSET`.
  Observed input: the copied-skill fixture at `test/find-harness.sh:218-221` with `TICK` absent and the other three tested exports set as above.
  Affected scope: this existing copied-skill `--env` assertion only; no locator behavior change requested.
  Falsifier: in a disposable full clone, temporarily remove `find-harness.sh:381` and run the existing `test/find-harness.sh`; the strengthened assertion should fail, while the restored locator should pass. [Unverified — needs clone run] for that mutation result.
- [Unverified — turn constraint] I did not run git or mutation-heavy suites in this relay worktree. The Producer's reported `origin/development...HEAD` file list and focused clone results are the available diff and suite evidence; the final qualifying gate remains outstanding.

VERDICT: FAIL
Basis: The round-1 behavior fixes and copied-skill guidance are supported, but the new `--env` control does not establish that the tick export exists or is usable.

Handing off to Producer — go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
