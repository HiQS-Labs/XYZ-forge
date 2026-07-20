# RELAY · UPGRADE.md accuracy + end-to-end verification
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
- Artifact under review: UPGRADE.md (repo root)
- Definition of Done: UPGRADE.md is (1) technically accurate against the actual repo — shim mechanics, the 11 entry points, xyz-sync subcommands, `:-` vs `-` bash empty-string semantics, exit codes, and the out-of-scope Bash script list all match reality — AND (2) truly end-to-end and repo-agnostic: no missing phase, no "one more thing" gap that would surface mid-upgrade, and genuinely runnable on a repo that is NOT this one, including a vendored `.xyz/` consumer.
- Producer: claude-a   ·   Reviewer: agy
- Handoff: cli-driven (agy)
- Started: 2026-07-20

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents may be different tools (e.g. Claude and agy) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top.
4. Stay tight. Requests and findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings, each with a concrete suggested fix where possible. The Producer decides each proposal and implements the approved ones — logging a disposition for every one.
6. Grade every finding: `[Blocker]` must fix · `[Should]` strong rec · `[Nit]` optional · `[Pass]` checked and sound. Answer the Producer's "Re-review this" questions in an `Answers:` block.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — to get proposals actioned in-thread set `Changes requested`, not `Approved`. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated`.
8. End your turn by committing it. If the log is gitignored or comments-only, write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.**
10. **Evidence contract — state your proof every turn.** Reviewer logs a verdict `Basis:` — `behaviorally proven` or `textual only`. UPGRADE.md is a runbook doc: `textual only` / `N/A — non-executable artifact` is expected, but the read must be against the artifact AND the repo files it describes.
11. **Reconcile claims against the file, not this log.** Since this is a doc artifact, the file check is the only backstop.

## Roles
- **Producer** — claude-a: authored UPGRADE.md, decides and implements proposals.
- **Reviewer** — agy: reviews against the DoD, proposes graded findings, sets a verdict. Never edits the artifact.

## Reviewer focus (this relay)
Verify UPGRADE.md against the ACTUAL repo, not just for internal consistency. Specifically check:
- **Shim mechanics:** does the described 6-line shim + `${XYZ_PYTHON:-0}` condition match all 11 entry points? Are the 11 files listed correct and complete?
- **`:-` vs `-` semantics:** is the empty-string trap claim correct bash? (`${VAR:-default}` substitutes on unset OR empty; `${VAR-default}` only on unset.) Is the flipped-default truth table right?
- **xyz-sync subcommands:** do `list` / `update <dir>|--all` / `check <dir>|--all` / `delete` actually exist in `relay-automation/xyz-sync.sh`?
- **Exit codes / test harness:** is `TEST_SOFT_FAIL=1` real and does it behave as described? Is the two-mode baseline method sound?
- **Out-of-scope Bash list:** are `relay-turn-lib.sh`, `marathon.sh`, `runner.sh`, etc. genuinely unported? Is the "permanently partial" claim honest?
- **End-to-end completeness:** is there any step an operator would hit mid-upgrade that the doc omits? (python3 version floor, the `_marathon_plan_node.js` Node dependency for marathon-plan, worktree/artifact divergence, fleet rollback cost.)
- **Vendored-consumer runnability:** §9 + §7 — can this actually be run from/against a `.xyz/` vendored copy, or is there a blocker the doc glosses?
Flag inaccuracies, missing steps, and vendored-consumer blockers. Do NOT edit UPGRADE.md.

---
## Log

### Round 1 · Producer · claude-a · 2026-07-20 16:18 PDT
**Did:** Authored UPGRADE.md — a 5-phase reversible runbook for flipping the `XYZ_PYTHON` default from Bash to Python: reversibility model (env var / git revert / re-vendor), the `:-`→`-` empty-string trap + `python3`-presence guard (Phase 2), the isolated flip commit (Phase 3), docs/discoverability (Phase 4), fleet propagation via `xyz-sync` (Phase 5), soak/abort criteria, and a portability section for non-origin repos incl. vendored `.xyz/` consumers.
**Review this:** Every item in "Reviewer focus" above. This is a doc that must be RUNNABLE elsewhere, so accuracy against the real repo matters more than prose. I especially want the bash `:-` vs `-` semantics double-checked, the 11-entry-point list confirmed complete, and any mid-upgrade "one more thing" gap called out now rather than discovered during the real upgrade. Confirm the vendored-`.xyz/` path in §7/§9 is actually executable and not hand-waved.
**Verification:** N/A — non-executable artifact (a runbook). Claims were grounded by reading the shim header, `xyz-sync.sh` usage block, and the PDDA front-matter spec before writing, but the doc itself runs nothing.
**Open questions:**
- Is the flipped-default truth table (§1) correct, especially the empty-string row?
- Is anything in the "out of scope / stays Bash" list actually ported (making the list wrong)?
- Does the marathon-plan Python path's Node dependency (`_marathon_plan_node.js`) need calling out as a precondition alongside `python3`?
**Commit:** none (comments only)

### Round 1 · Reviewer · agy · 2026-07-20 16:25 PDT
VERDICT: FAIL
Basis: textual only (doc against repo state)
**Findings & proposals:**
- `[Pass]` Shim mechanics: Confirmed exactly 11 entry points contain the `${XYZ_PYTHON:-0}` shim. The out-of-scope list (`relay-turn-lib.sh`, `marathon.sh`, etc.) is genuinely unported.
- `[Pass]` `:-` vs `-` semantics: The bash behavior claim and truth table are entirely correct (`:-` acts on empty and unset, `-` only acts on unset).
- `[Pass]` `xyz-sync.sh`: The `list`, `update`, `check`, and `delete` subcommands are all present and function as documented.
- `[Pass]` Test harness: `TEST_SOFT_FAIL=1` is implemented correctly in `test/_setup.sh` and the two-mode baseline subtraction method is sound.
- `[Blocker]` Node.js dependency: The python port of `marathon-plan.sh` (`utils/py/marathon_plan.py`) shells out to `node utils/py/_marathon_plan_node.js` and explicitly errors if `node` is missing from `PATH`.
  - **Proposal:** Add `node --version` to the Preconditions (§2) alongside `python3`.
- `[Blocker]` Vendored consumer runnability: §9 tells the operator to regenerate the parity gaps "on the target with the `TEST_SOFT_FAIL=1` two-mode sweep". However, point 4 immediately notes that a vendored copy "has no `PROJECT/` or `validate.sh` of its own". Without `validate.sh`, the two-mode sweep cannot be run as described.
  - **Proposal:** Clarify how a vendored consumer resolves Phase 1. If leaf consumers are not expected to resolve parity gaps themselves, state that Phase 1 is skipped for vendored consumers. Otherwise, provide the correct commands for testing a vendored harness.
**Answers:**
- *Truth table empty-string row correct?* Yes, empty string will evaluate to `""` with `${XYZ_PYTHON-1}`, which falls back to Bash, exactly as intended.
- *Are out-of-scope scripts actually ported?* No, none of them have `.py` equivalents in `utils/py/`, making the list accurate.
- *Does `_marathon_plan_node.js` need calling out?* Yes, see the blocker finding above.
**Commit:** pending (harness will commit)

### Round 2 · Producer · claude-a · 2026-07-20 16:32 PDT
**Decisions on proposals:** (both Blockers independently verified against the repo before disposing)
- `[Blocker]` Node.js dependency — **Implemented.** Verified real: `utils/py/marathon_plan.py:105-107` runs `subprocess.check_call(["node","--version"])` and `die("node is required ... but not found in PATH")` before delegating to `_marathon_plan_node.js`. Added `# (a2) node present` to Preconditions §2 (UPGRADE.md:108-112) AND an "Interpreter matrix" table (UPGRADE.md:138+) stating only marathon-plan needs Node, so a Node-less box can still flip the other 10 and leave `utils/marathon-plan.sh` on its Bash default (per-file flip). Also added a §10 checklist line.
- `[Blocker]` Vendored-consumer runnability contradiction — **Implemented.** Verified real: two live `.xyz/` copies (`rebalance-OS/.xyz`, `pdda/.xyz`) have **no `validate.sh`** but DO ship `test/_setup.sh` + `utils/py/`. Root cause of the contradiction: §9 conflated a full harness clone with a vendored leaf. Rewrote §9 (UPGRADE.md:356+) to split **Type A (full clone — runs Phases 1–8)** vs **Type B (vendored leaf — skips Phases 1 & 3, inherits parity, verifies via the consuming repo's own smoke path + `xyz-sync check`)**. A leaf never runs the two-mode sweep and never hand-edits `.xyz/` shims — it receives the flip only by `xyz-sync update` from an already-flipped root. Added a §10 "determine target TYPE first" line.
**Did:** Both fixes are doc-only additions; no claim in the original doc was weakened, only made correct. The 4 `[Pass]` findings (shim count, `:-`/`-` semantics, xyz-sync subcommands, TEST_SOFT_FAIL) I also independently re-verified before this relay — 11 exec-python sites exactly, `${V-0}` empties to `""`→Bash, out-of-scope list has zero `.py` twins.
**Verification:** N/A — non-executable artifact. Fix landing reconciled by re-grep against UPGRADE.md: Blocker-1 text at lines 108-112/138, Blocker-2 text at lines 356/359/377. Both present.
**Re-review this:** (1) Is the Type-A/Type-B split in §9 now internally consistent — does the leaf path (skip Phases 1 & 3, inherit-and-verify) fully resolve the "no validate.sh" contradiction, or is there still a leaf step that assumes suite infrastructure the leaf lacks? (2) Does the Interpreter matrix + the per-file "partial flip" escape hatch correctly handle the Node dependency, or does any other twin have a hidden non-python runtime dep I missed (e.g. does any of the other 10 shell out to node/jq/awk in a way that would brick it)?
**Commit:** pending (harness will commit)

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
