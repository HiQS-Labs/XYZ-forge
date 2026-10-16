---
Goal: Final QA — GH-1098 Scope A implementation (A1–A4)
Date: 2026-10-16
NEXT: claude (Producer)
STATUS: Approved
---

# Context

Adjudicate the committed implementation of #1098 Scope A against the Approved plan `PROJECT/2-WORKING/GH-1098-SHIFT-PHASE3.md` (plan QA: `relay-system/2026-10-16/gh1098-plan-qa.md`, Approved round 3) and the retained evidence under `TESTS-RESULTS/2026-10-16+GH-1098/` (`provenance.jsonl` first).

Operational envelope: local developer harness, single repo, one operator. Four surgical edits in two files. **No new tests, suites, registry entries or gate machinery (AGENTS.md "No new tests", GH-831)** — a new test file or registry entry in the diff is itself a finding. Grade against the plan's stated requirements and commensurate complexity.

Diff to review: `git diff 05bd9303..HEAD -- utils/py/jog_run.py utils/py/swarm_preflight.py` (read-only). Commits: `4dc76a33` (A1–A4), `e358dd86` (shlex import), `2d7dba09` (A4 bash form).

Read in full:
- `utils/py/jog_run.py` `run_marathon_phase` (~:521–560 and ~:583–595) and `promote_contract_to_working` (~:1177–1225); the legacy preflight call (~:1740–1752)
- `utils/py/swarm_preflight.py` ~:1388–1402 and the packet `Gate:` line (~:1845)
- `TESTS-RESULTS/2026-10-16+GH-1098/provenance.jsonl`, `manual-A1-A3-{candidate,parent}.json`, `manual-A2-A4-{candidate,parent}.json`

Questions:

1. **A1.** Does the marathon path now resolve `swarm_preflight.py` root-first and pin `SWARM_PREFLIGHT_ROOT=root` on both the marathon and legacy calls? Is the "resolved outside this root" log computed correctly (three dirname levels from `utils/py/swarm_preflight.py`)? Does the vendored `.xyz/` fallback still work when `root` has no copy? Does this satisfy #1093 (pin OR refuse)?
2. **A2.** Does the hoisted frontmatter block set `status: Active`/`updated` whether or not a Status table exists, insert the table only when absent, fill only absent `updated`/`owner`/`goal`, never overwrite existing values, and emit the marker as a YAML `#` comment? Any case where a doc without a leading `---` is mishandled? Is `.lstrip()` applied only when a table is inserted (so existing body spacing is preserved otherwise)?
3. **A3.** Does `env.setdefault("RELAY_TURN_IDLE_S", env.get("RELAY_TURN_TIMEOUT_S", "900"))` express "idle bound = wall cap, operator export wins" for every agy turn a jog invocation dispatches, and nothing else? Does it reach `agy-turn.py` unchanged through marathon-drive and relay-drive?
4. **A4.** Does the rewrite trigger only for the three default spellings, produce `bash validate.sh --auto <quoted ref>`, propagate into the invocation JSON `gate` and the `--pre-advance-cmd` argv, and record the routing in the packet? Why did `./validate.sh` form fail T33/T36 and is the bash form the smallest correct fix? Any contract gate that should have been rewritten and is not, or vice versa?
5. **Evidence.** For each of A1–A4, do the candidate/parent JSONs show the red control failing on the parent and passing on the candidate for the plan's stated reason? Is the contamination of the first full-gate run correctly described and excluded from evidence? What remains `[Unverified — needs clone run]` pending the clean full gate and Scope C?
6. **Scope and hygiene.** Any new test file, registry entry, flag, config key, or duplicate writer in the diff? Any unrelated change? Does the persisted rating 75/55/50/55 still match the evidence?

Rules (GH-681): a `[Blocker]`/`[Should]` requesting a behaviour change carries `Observed input:`, `Affected scope:`, `Falsifier:`; a `[Blocker]` cites an observed failure. Measure read-only only; no suite runs in the relay worktree.

Write your verdict (`**Verdict:** Approved` or `**Verdict:** Changes requested`), set STATUS, and close with `VERDICT: PASS|FAIL` plus `Basis:`.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log

### Round 1 · Reviewer · codex

**Verdict:** Approved

Ship the bounded Scope A implementation, subject to the already-required clean clone gate. No material implementation finding in the inspected A1–A4 source. This approval does not attest Scope C completion or external acceptance of the proposed issue-requirement adjustments.

1. **A1 — source and retained red control agree.** `run_marathon_phase` prefers the root's preflight, falls back to `harness_home()` only when absent, and pins `SWARM_PREFLIGHT_ROOT=root`. The legacy preflight call also pins it. Three dirname operations on `/repo/utils/py/swarm_preflight.py` yield `/repo`; realpath comparison gives the intended outside-root diagnostic. The vendored fallback remains reachable and the root pin is consumed before capture lookup and target selection. This implements the plan's pin-and-log choice allowed by #1093. The A1 candidate receipt reports exit 0 and clone `target_root`; the parent reports exit 6 and the missing clone-only capture. This is a preflight reproduction, not evidence of an actual jog-to-marathon dispatch; the receipt correctly says so. Vendored fallback execution and live dispatch remain unverified.

2. **A2 — correct for the planned frontmatter-bearing captures.** The rewrite now runs independently of Status-table insertion. It refreshes existing `status`/`updated`, supplies absent `updated`/`owner`/`goal`, preserves existing owner/goal, and uses a YAML comment marker. Existing updated values are intentionally refreshed to today, as the approved plan specifies; “fill only absent” does not mean preserve a stale updated date. `.lstrip()` occurs only when inserting the table. The retained paired receipts show six parent missing-key errors versus zero candidate errors, one Status heading per seed, and preserved owner/goal. A narrow in-memory probe of the actual extracted formatting statements confirmed both spacing branches and the YAML comment. A document without leading YAML frontmatter receives no synthesized frontmatter (and no missing status is synthesized either); such an already-invalid capture remains invalid for PDDA. This pre-existing input limitation is outside the three-missing-key repair and is not evidence that arbitrary malformed captures now pass.

3. **A3 — appropriately scoped inherited env.** The new `setdefault` is local to marathon dispatch: operator `RELAY_TURN_IDLE_S` survives, otherwise it uses exported `RELAY_TURN_TIMEOUT_S` or 900. Preflight's invocation env does not overwrite either key. `marathon_drive.py:3386–3417` copies the env into relay-drive; `relay_drive.py:902–905` launches the turn with inherited env; agy reads the wall cap at :409 and idle cap at :463. No driver reset of these values was found in those inspected paths. It applies to agy builder and reviewer turns in this jog marathon, with non-jog defaults unchanged. Legacy jog execution is not newly covered; the approved fix is at the default marathon-dispatch seam. The paired A3 JSONs demonstrate the source/env-emulation difference (candidate 900, parent absent; export 0 preserved), **not** an executed child-env red control or absence of an idle kill. Live propagation and timing remain Scope C evidence requirements.

4. **A4 — one canonical gate value reaches both consumers.** Only the three specified default strings (after outer whitespace stripping) normalize to `bash validate.sh --auto <shlex-quoted target.ref>`. Custom/explicit-tier commands pass through. The same `gate_cmd` feeds invocation JSON, the `--pre-advance-cmd` argv element, and the packet's routing note. The final candidate receipt is at c2fcf906 and records the bash form in all three, versus parent `bash ci-local.sh`; the explicit-tier control stays unchanged. T33/T36's earlier failure is explained by :1562–1590: direct `./validate.sh` requires executable permission, while the existing bash branch checks the script exists. Changing the generated spelling to the plan's bash form uses that existing validator and is the smallest correction. Target-ref quoting round-trips as one argument in a narrow shlex probe. Single-ref `--auto` includes tracked working-tree differences, so the post-landing development baseline remains necessary for the timing claim. No additional gate spelling is required by the approved three-spelling contract.

5. **Evidence and limitations.** Read `provenance.jsonl` first and all four nonempty manual JSONs. Their differences are meaningful for A1, A2 and A4; A3 is explicitly static/emulated. The first full run was contaminated by staged parent-control capture documents, and is correctly excluded rather than treated as a clean regression/gate result. The provenance retains the real T33/T36 failure, its parent 100/100 control, the bash-form fix, and the subsequent candidate 100/100 focused-suite receipt. I reviewed retained receipts; I did not independently rerun suites. **[Unverified — needs clone run]** Clean final full `ci-local.sh`, final-SHA gate/hosted attestation, actual jog dispatch and inherited child env, absence of early idle kill, and post-landing routed-gate duration/Scope C PR-ready outcomes. Approval must not be used to claim those pending outcomes.

6. **Scope and rating.** The inspected implementation adds no CLI flag, config key, duplicate writer, or test/gate mechanism; it extends the existing dispatch, promotion and packet writers. The persisted 75/55/50/55 remains consistent with recoverable wasted runs and one day's small sample; it does not establish a longer recurrence trend. Complete changed-file hygiene is **not independently attested this turn**: the explicit no-git rule prevented the requested `git diff 05bd9303..HEAD`, and a read-only loose-object comparison could not resolve the packed/abbreviated object. The harness should check the actual changed-file manifest, including the no-new-tests rail, before publication. No unrelated implementation was observed in the requested source sections.

Review evidence: Verify-tier intent. Both `list_projects` pages returned 84 projects, none rooted at this worktree. Canonical XYZ-forge graph generation 2026-09-01T15:54:30Z has changed metadata for runtime paths and untracked harness_paths metadata. The symbol lookup was provisional; exact local source was used for all material claims, including both env consumers and gate validation. No index was created/refreshed. The test-scope coverage response has known gaps and is not used as proof of test-file hygiene.

Read-only source/receipt commands (`sed`, `cat`, literal `rg`) exited 0. One optional tick-source glob lookup failed to expand and supplied no evidence. Probe command: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 - <<'PY'` with `ast.parse(Path("utils/py/jog_run.py").read_text())`, extraction of only the `status_table` through formatting statements, and an in-memory subprocess stub returning owner `Noel Saw`; no promotion, file-writing function, git subprocess, fixture or suite was executed. Exit 0; decisive output: `no-table: status Active; updated present; owner/goal preserved; one Status; body spacing correct`, the same for `has-table`, `missing keys: updated/owner/goal inserted; marker is YAML comment`, `no leading frontmatter: Status inserted; YAML not synthesized (existing invalid-input limitation)`, `gate ref quoting: round-trip retains one argument`, and `root logging anchor: /repo`. The optional direct loose-object reader exited 2, `UNVERIFIED direct loose-object comparison: object unavailable or ambiguous`; no diff claim rests on it. `tick done --help` exited 2 with usage and did not change the held token.

Containment: only this relay file was edited; scratch setup stayed under `.relay-scratch/tmp`. No git command, validate.sh, test suite, pytest or executable fixture was run. Handing back to claude with done; STATUS: Approved.

VERDICT: PASS
Basis: Bounded A1–A4 implementation matches the approved technical plan and retained focused evidence; no material source finding. Clean full-gate, complete diff hygiene and live Scope C claims remain unverified as specified above.
