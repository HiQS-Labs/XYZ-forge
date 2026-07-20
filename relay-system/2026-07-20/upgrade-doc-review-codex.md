# RELAY · UPGRADE.md QA — independent Codex pass
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 5

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup (read the real files / the latest `git show <last commit>` diff; cite `file:line`):
   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; you only append findings here. **Before you set `Approved`, re-read the artifact file itself** (not this log) and confirm every prior `Implemented` fix is actually present and complete — any that is missing or partial → set `Changes requested` with a `[Blocker] claimed-implemented-but-absent @ file:line` instead. For a doc artifact this file check is the only backstop there is.
   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change, then add new work. **Before you flip `NEXT`, re-read the artifact and confirm each `Implemented → @ file:line` actually landed in the file** — cite the line as it appears in your commit diff. A claim you can't point to in the file is not done.
4. **Append ONE block** at the very bottom, directly **above** the marker line (`<!-- ↓↓↓ NEXT TURN ... -->`). Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**`; a Producer block carries `**Decisions on proposals:**` + `**Did:**` + `**Re-review this:**` + `**Commit:**`. (Need the exact shape? Mirror the most recent block of the other role above.)
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`); the Producer bumps `ROUND` when opening a new cycle.
6. **Commit only the files you touched** (artifact + this log): `git commit -m "relay(<slug>): <your-label> r<N>"`, then put the short hash in your block's `Commit:` line and `git commit --amend --no-edit`. Push if the team shares a remote.
7. **Stop.** Tell the operator your one-line result (e.g. "Changes requested, 1 Blocker — Producer's turn").

## Setup
- Artifact under review: UPGRADE.md (repo root, 435 lines)
- Definition of Done: UPGRADE.md is (1) technically accurate against the actual repo — shim mechanics, the 11 entry points, `xyz-sync` subcommands, `:-` vs `-` bash empty-string semantics, exit codes, the interpreter matrix (python3/node), and the out-of-scope Bash list all match reality — AND (2) truly end-to-end and repo-agnostic: no missing phase, no "one more thing" gap that surfaces mid-upgrade, genuinely runnable on a repo that is NOT this one incl. a vendored `.xyz/` (Type-B) consumer.
- Producer: claude-a   ·   Reviewer: codex
- Handoff: cli-driven (codex)
- Started: 2026-07-20
- Prior QA: an independent agy `/relay-xyz` pass already ran (thread `upgrade-doc-review.md`) and reached Approved after fixing 2 blockers (Node precondition; vendored Type-A/B split). This Codex pass is a SECOND, independent reviewer — do not defer to agy's verdict; re-derive your own.

## Ground rules
1. This file is the single source of truth. The two agents may be different tools (Claude and Codex) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top.
4. Stay tight. Requests and findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings with concrete fixes. The Producer decides and implements each.
6. Grade every finding: `[Blocker]` must fix · `[Should]` strong rec · `[Nit]` optional · `[Pass]` checked and sound.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved**. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated`.
8. End your turn by committing it (harness handles the commit for a driven turn).
9. **One window at a time, clean tree at every handoff.**
10. **Evidence contract.** Reviewer logs a verdict `Basis:` — `behaviorally proven` or `textual only`. This is a runbook doc: `textual only` is expected, but the read must be against the artifact AND the repo files it describes. You MAY run read-only commands (grep, cat, git) to check claims — you have a throwaway worktree; use it.
11. **Reconcile claims against the file, not this log.** Doc artifact → the file check is the only backstop.

## Roles
- **Producer** — claude-a: authored UPGRADE.md, decides and implements proposals.
- **Reviewer** — codex: reviews against the DoD, proposes graded findings, sets a verdict. Never edits the artifact.

## Reviewer focus (this relay) — be adversarial; a prior reviewer already passed it, so hunt what it missed
Verify UPGRADE.md against the ACTUAL repo. High-value angles:
- **Correctness of the bash claims:** `${VAR:-0}` vs `${VAR-0}` empty-string semantics and the flipped-default truth table (§1). Is the "fail-safe direction" claim (anything ≠ `1` → Bash) actually true of the shim as written?
- **Completeness of the interpreter matrix (§2):** the doc claims only `marathon-plan` needs `node`. Independently check every twin in `utils/py/` for a non-python runtime dependency (node/jq/awk/etc. via subprocess) — is the matrix right, or is another entry point secretly non-pure-python?
- **The 11 entry points:** confirm the count and list; confirm the out-of-scope Bash list (`relay-turn-lib.sh`, `marathon.sh`, `runner.sh`, …) genuinely has no `.py` twin and no shim.
- **`xyz-sync.sh` subcommands (§7):** do `list`/`update`/`check`/`delete` exist and behave as the doc implies? Is `check`'s drift semantics described correctly?
- **Phase-2 hardening realism (§4):** the doc proposes a `python3`-presence guard and `:-`→`-` at 11 sites, and a "one-distinct-line" invariant check. Is that grep invariant actually correct given `marathon-plan.sh`'s shim has an EXTRA `--zones-config` translation line (GH-154) that makes it NOT byte-identical to the other 10? Flag if the invariant would false-positive.
- **Vendored Type-B path (§9):** is the "leaf skips Phases 1 & 3, inherits parity" model actually executable, or does any leaf step still assume infrastructure a `.xyz/` lacks?
- **Any mid-upgrade "one more thing":** ordering hazards, a proof step that can't actually be run as written, a rollback lever that doesn't work in practice, `.xyz/` lock/driver interactions during a fleet update.
Flag inaccuracies, missing steps, and vendored-consumer blockers. Do NOT edit UPGRADE.md.

---
## Log

### Round 1 · Producer · claude-a · 2026-07-20 16:37 PDT
**Did:** Submitting UPGRADE.md (435 lines) for an independent Codex QA pass. The doc is a reversible end-to-end runbook for flipping the `XYZ_PYTHON` default Bash→Python: reversibility model (env / git revert / re-vendor), the `:-`→`-` empty-string trap + `python3`-presence guard (Phase 2), interpreter matrix (python3 always; node for marathon-plan only), isolated flip commit (Phase 3), docs (Phase 4), fleet propagation via `xyz-sync` (Phase 5), soak/abort criteria, Type-A/Type-B portability (§9).
**Review this:** Everything in "Reviewer focus" above. This already passed an agy review — I want Codex to find what agy DIDN'T. Especially: (a) is the §4 "one-distinct-line" grep invariant wrong given marathon-plan.sh's extra GH-154 `--zones-config` shim line? (b) does any twin besides marathon-plan have a hidden runtime dep? (c) any proof/rollback step that can't actually run as written?
**Verification:** N/A — non-executable artifact (runbook). Claims were grounded against the shim header, xyz-sync usage, marathon_plan.py, and two live `.xyz/` copies before writing; the doc itself runs nothing.
**Open questions:**
- Is the fail-safe direction claim airtight, or is there an input that routes to Python unexpectedly?
- Is the marathon-plan.sh shim genuinely NON-identical to the other 10 (extra flag-translation), and if so does §4's invariant check need to account for it?
**Commit:** none (comments only)

### Round 1 · Reviewer · codex · 2026-07-20 16:41 PDT
**Verdict:** Changes requested
**Basis:** textual only — reconciled against `UPGRADE.md` and the live shim, Python-twin, vendor, sync, and locator sources.
**Findings & proposals:**
- [Blocker] `UPGRADE.md:105-106` calls `python3 --version` but only says it “must succeed”; Python 3.7 passes that command despite the stated >=3.8 hard gate (`UPGRADE.md:135-136`). Add an executable version predicate (for example `python3 -c 'import sys; raise SystemExit(sys.version_info < (3, 8))'`) and retain the readable version output. Otherwise the documented gate can approve an interpreter that the runbook says must block the flip.
- [Blocker] `UPGRADE.md:114-116` fetches `origin <branch>` and then compares `origin/<branch>...HEAD`. An explicitly fetched branch is recorded in `FETCH_HEAD`; it need not refresh the remote-tracking ref the comparison reads. Replace it with a fetch that refreshes the tracking refs (e.g. `git fetch -q origin` / `--prune` as appropriate) before `rev-list`, or compare the freshly fetched `FETCH_HEAD` deliberately. The present “CURRENT branch” proof can accept a stale `origin/<branch>`.
- [Blocker] Type-B discovery is not runnable as written: `UPGRADE.md:369-372` names `find-harness.sh`, but the shipped locator is `skills/relay-xyz/find-harness.sh` (`skills/relay-xyz/find-harness.sh:8-16`) and no root-level locator exists. Add a concrete Type-A/Type-B-safe command, then `cd` to its output; for example select `.xyz/skills/relay-xyz/find-harness.sh` in a leaf and `skills/relay-xyz/find-harness.sh` in a clone. Do not direct this flow through `--env` until GH-234 is fixed: its current `TICK_REPO_ROOT` export is known to be one directory too deep for a vendored harness.
- [Should] Qualify the “10 ... twins | `python3` only” matrix at `UPGRADE.md:138-143` as “only additional language runtime” (or enumerate operational dependencies). It is otherwise false literally: `utils/py/marathon_drive.py:139,434-444` invokes `date`, `git`, and `/bin/bash`; `utils/py/relay_drive.py:361` invokes the Bash `consult.sh`; `utils/py/aider-turn.py:80-81` invokes `sed`. I found no second Node/JS twin dependency; `marathon_plan.py:105-142` is the sole Node requirement.
- [Nit] `UPGRADE.md:232-239`'s condition-line invariant is sound — the extra `--zones-config` translation in `utils/marathon-plan.sh:11-20` does not enter the filtered condition-line check — but reword “byte-identical except the twin filename” to explicitly exempt that shim, so the stated invariant matches the actual design.
- [Pass] The 11-entry-point list matches every live `${XYZ_PYTHON:-0}` shim, the post-hardening `:-` versus `-` truth table is correct, and `xyz-sync` supports `list`/`update`/`check`/`delete`; its `check` is report-only and compares both `tick_version` and `source_commit` (`relay-automation/xyz-sync.sh:296-335`).
**Commit:** harness-managed

### Round 2 · Producer · claude-a · 2026-07-20 16:48 PDT
**Decisions on proposals:** (each verified against the repo before disposing)
- `[Blocker]` python3 version gate not enforced — **Implemented.** Verified: `python3 --version` exits 0 on any version, so the ">=3.8 hard gate" was unenforced prose. Replaced §2(a) with an executable predicate `python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3,8) else 1)'` that actually fails <3.8, keeping the readable `--version` line too (UPGRADE.md:106-109).
- `[Blocker]` `git fetch origin <branch>` may leave `origin/<branch>` stale — **Modified.** Verified the remote's refspec is `+refs/heads/*:refs/remotes/origin/*`, so on a standard remote the explicit-branch fetch *does* update the tracking ref (the finding overstates severity as a hard blocker for this repo). BUT the concern is real for non-standard refspecs, and bare `git fetch origin` is unconditionally correct at zero cost — so I adopted the safer bare form and documented exactly why (UPGRADE.md:114-120). Downgraded severity, implemented the fix.
- `[Blocker]` Type-B locator not runnable as written — **Implemented.** Verified: no root-level `find-harness.sh`; the shipped locator is `skills/relay-xyz/find-harness.sh` (Type-A) / `.xyz/skills/relay-xyz/find-harness.sh` (Type-B). §9 point 1 now gives both concrete paths + a `--check` invocation, AND adds the GH-234 caveat you flagged (don't use `--env` on a vendored install — its `TICK_REPO_ROOT` is one dir too deep) (UPGRADE.md:384-393).
- `[Should]` interpreter matrix "python3 only" literally false — **Implemented.** Verified the external calls you cited (`marathon_drive.py:139,424,444` → date/bash/rtl; `relay_drive.py:106` + consult.sh; `aider-turn.py:80` → sed). Reworded the matrix to "additional *language* runtime" and added an explicit note that every twin still needs POSIX tools + git + bash — not pure-Python (UPGRADE.md:145-152).
- `[Nit]` byte-identical prose — **Implemented.** Reworded §4 to state the shims share one identical *condition line* but are NOT wholly byte-identical (marathon-plan.sh's GH-154 zones-config block), and scoped the invariant explicitly to the condition line (UPGRADE.md:244-251).
**Did:** All 5 findings actioned (3 Impl + 1 Modified + 1 Impl). Independently confirmed your `[Pass]` items and your "no second Node/JS twin" conclusion — matches my own check (the `"node"` in `swarm_preflight.py:652` is a gate-command allowlist string, not a subprocess call).
**Verification:** N/A — non-executable artifact. Fix landing reconciled by re-grep: B1@108, B2@118, B3@387-389, Should-4@145, Nit-5@247. All present.
**Re-review this:** (1) Is the §2(a) version predicate correct and does it fail-closed as intended? (2) Is the §9 Type-B locator sequence now actually runnable on a `.xyz/` leaf, GH-234 caveat included, or does anything still assume the missing root locator? (3) Does the reworded interpreter-matrix note now accurately bound the runtime deps without over- or under-claiming?
**Commit:** pending (harness will commit)

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
