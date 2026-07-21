# RELAY · GH-255 Python cutover — parity ports review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-20.
-->

NEXT: claude-a
STATUS: Escalated
ROUND: 5 / 5

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-255-python-cutover-parity-ports-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/gh255-branch.diff** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-07-20/gh255-branch.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-20
- Definition of Done: The Python twins in the diff (`utils/py/*.py`) are FAITHFUL, CORRECT ports of their Bash reference counterparts (`relay-automation/*.sh`, `utils/*.sh`) — matching exit codes, stdout/stderr strings, and file outputs; **no containment/security regression** (esp. `marathon_drive.py` lock/gate/off-lane logic, `rtl.py`, `codex-turn.py`); and no correctness bugs in edge cases, error handling, or path resolution. Context: the two-mode `TEST_SOFT_FAIL=1 validate.sh` sweep is **Python 117/117, Bash 116/117, zero Python-attributable failures**. Grade the DIFF for real defects a green test suite could still miss (e.g. the `marathon_plan.py` pre/post-processing shims vs a direct engine sync; the `codex-turn.py` append-vs-truncate + RTL_LOG ordering; the `relay_drive.py` GH-198/GH-245 logic; the `consult.py` GH-235 classifier).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · codex · Round 1

- [Blocker] The declared artifact `.relay-artifacts/gh255-branch.diff` is absent in this isolated worktree (`sed` reports “No such file or directory”), so there is no implementation diff to assess. Fix: seed the declared read-only diff into `.relay-artifacts/gh255-branch.diff` before the next review.
- [Blocker] The Definition of Done is the unfilled placeholder `_&lt;fill in the acceptance criteria the Reviewer grades against&gt;_` (Setup), so parity cannot be graded against an agreed acceptance contract. Fix: replace it with concrete Python-cutover parity acceptance criteria.

Verdict: Blocked.

### Reviewer · codex · Round 2

- [Blocker] `rtl_default_log` does not faithfully port `rtl_transcript_root` when `XYZ_ARCHIVE_ROOT` is set: it accepts a relative archive path, neither verifies that the archive exists/is a Git repo nor namespaces it as `relay-system/<repo-slug>`, and then creates logs at that different location (`.relay-artifacts/gh255-branch.diff:1124-1152`). This breaks the archive contract and permits persistent relay logs to land in an unintended target-relative path. Fix: port the Bash resolver in full — reject non-absolute/missing/non-Git archive roots, derive the sanitized origin-or-basename repo slug, and return `<archive>/relay-system/<slug>`; retain the tmp fallback when that resolver or `mkdir` fails.
- [Should] The `marathon_plan.py` doc-selection shim normalizes one physical line at a time (`.relay-artifacts/gh255-branch.diff:796-830`), but the shared Node/Bash ledger parser assembles a bullet from its continuation lines before collecting links. A ledger item with a distractor doc on its first line and its own `GH-<n>` doc on a continuation line remains unnormalized, so the stale Node `docOf` still selects the wrong document. Fix: parse and rewrite complete ledger bullet blocks using the same boundary rules as the engine, collect all block links for `_node_pick`/`_bash_pick`, and down-convert rival links across the selected block.

Verdict: Changes requested.

### Producer · claude-a · Round 2

**Decisions on proposals (both verified against the repo before implementing):**
- [Blocker] rtl_default_log / archive port — **Implemented** → `utils/py/rtl.py`: rewrote `_rtl_transcript_root` to faithfully mirror Bash `rtl_transcript_root` — on `XYZ_ARCHIVE_ROOT` set it now rejects non-absolute / missing / non-git roots (prints the same diagnostics, returns `None` so `rtl_default_log` takes the `$TMPDIR` fallback exactly as the Bash `... || fallback`), and returns `<archive>/relay-system/<repo-slug>` via a new `_rtl_repo_slug` (origin remote basename else dir basename, sanitized to `[A-Za-z0-9._-]`, never empty/`.`/`..`/leading-`-`). Was a naive absolutize-only stub. · Proof: `python3 -c ast.parse` clean; `test/relay-turn-trace.sh` still 20/0 both modes (common path unchanged).
- [Should] marathon_plan.py continuation-line normalization — **Implemented** → `utils/py/marathon_plan.py`: `_normalize_roadmap` is now block-aware — each `- ` bullet is grouped with its continuation lines (until the next bullet / blank / heading), links collected across the whole block, and rival md-doc links pruned across every line of the block. · Proof: `test/marathon-plan.sh` 60/0 both modes (no regression); functional check — input with `[distractor](…/OLD.md)` on the bullet line and `[right](…/GH-111-right.md)` on a continuation line now down-converts the distractor to plain text while keeping the lane's own doc.

**Verification:** `relay-turn-trace` 20/0, `marathon-plan` 60/0 (both modes); full two-mode `validate.sh` remains Python 117/117 / Bash 116/117. Committed on `gh255-phase2-toggle-harden` (`4ca9e59`).
**Re-review this:** the regenerated `utils/py/*.py` diff (`.relay-artifacts/gh255-branch.diff`) now includes both fixes — please confirm the archive-resolver parity and the block-aware pruning, and approve if sound.
**Commit:** (this relay file)

### Reviewer · codex · Round 3

- [Should] The new roadmap shim still does not use the engine's continuation boundaries: it ends a block on any blank, heading, or `lstrip()`ed `- ` line (`.relay-artifacts/gh255-branch.diff:809-829`). The canonical parser ends only on an unindented `##`/`###`/`- **` ledger boundary, so a blank line or nested list before the own `GH-<n>` document makes the Python shim miss the rival-link pruning and preserves the wrong Node selection. Fix: use the canonical boundary predicates exactly and only normalize ledger bullets (`^- \*\*`).
- [Should] `_rtl_repo_slug` accepts Unicode alphanumerics through `str.isalnum()` (`.relay-artifacts/gh255-branch.diff:1147-1172`), contrary to the Bash contract's ASCII-only `[A-Za-z0-9._-]` sanitizer. Archive paths therefore diverge for a remote or directory name containing, for example, `é`. Fix: test membership in an explicit ASCII alphabet for both the repository and task slugs, replacing every other character with `_`.
- [Should] `rtl_default_log` invokes `_rtl_transcript_root` directly (`.relay-artifacts/gh255-branch.diff:1183-1201`), so an invalid `XYZ_ARCHIVE_ROOT` writes the resolver diagnostic to stderr before falling back. Bash deliberately calls the resolver with stderr redirected and emits only the historical fallback path behavior. Fix: suppress/capture resolver stderr within `rtl_default_log` while retaining diagnostics when `_rtl_transcript_root` is called directly.
- [Should] The consult provenance classifier hard-codes its three-line window via the default parameter (`.relay-artifacts/gh255-branch.diff:168-197`) and ignores `RTL_CITATION_WINDOW`, while Bash reads that environment override. Fix: derive the default window from `RTL_CITATION_WINDOW` with awk-compatible numeric semantics before scanning claims.

Verdict: Changes requested.

### Producer · claude-a · Round 3

**Decisions (all 4 verified against the Bash reference, all Implemented) — commit `b52b0f9`:**
- [Should] marathon_plan continuation boundaries — **Implemented** → `_normalize_roadmap` now uses the canonical ledger boundaries: a block starts at an unindented `^- \*\*` bullet and ends ONLY at the next unindented `##`/`###` heading or `- \*\*` bullet; blank lines, nested lists, and wrapped continuation lines stay in-block. Only `^- \*\*` ledger bullets are normalized.
- [Should] `_rtl_repo_slug` Unicode — **Implemented** → both the repo slug and the `rtl_default_log` task slug now sanitize against an explicit ASCII alphabet (`_ascii_slug` over `[A-Za-z0-9._-]`), matching Bash `tr -c` instead of Python `str.isalnum()` (which passed Unicode letters like `é`).
- [Should] `rtl_default_log` resolver stderr — **Implemented** → `_rtl_transcript_root` gained a `quiet` flag; `rtl_default_log` calls it with `quiet=True` (Bash redirects the resolver's stderr on the fallback path), while direct callers keep the diagnostics.
- [Should] consult `RTL_CITATION_WINDOW` — **Implemented** → `rtl_has_uncited_claim` + `rtl_classify_cited_claims` now derive the window from `RTL_CITATION_WINDOW` (awk-compatible numeric coercion, default 3) instead of a hardcoded 3.

**Verification:** relay-turn-trace 20/0, marathon-plan 60/0, consult 62/0 (both modes). Full two-mode sweep unchanged (Python 117/117, Bash 116/117).
**Re-review this:** regenerated `utils/py/*.py` diff includes all four fixes.
**Commit:** (this relay file)

### Reviewer · codex · Round 4

- [Blocker] Python drops the Bash `--requires-test` safety contract: its parser neither declares that flag nor rejects it (`utils/py/marathon_drive.py:52`, `utils/py/marathon_drive.py:69`), and its success path approves/resets the lane immediately after the pre-advance gate (`utils/py/marathon_drive.py:605`). Bash snapshots the pre-phase HEAD and rejects approval when the nominated test has not changed (`relay-automation/marathon-drive.sh:487`, `relay-automation/marathon-drive.sh:871`). Thus under `XYZ_PYTHON=1`, a caller can pass `--requires-test test/foo.sh`, receive exit 0, and emit `marathon.phase.approved` without adding or modifying that test. Fix: port the argument, baseline capture, `requires_test_delta` check, `requires-test-missing` escalation, and exit-5/telemetry behavior before success side effects.

Verdict: Changes requested.

### Producer · claude-a · Round 4 (post-escalation disposition)

The relay reached the round cap (4/4) still finding NEW real issues each round — the "don't loop
forever" guardrail fired as designed. The single r4 finding was a genuine **[Blocker]** and is fixed:

- [Blocker] GH-249 `--requires-test` safety contract dropped — **Implemented** → `utils/py/marathon_drive.py` (commit `4418122`): declared `--requires-test`, snapshot `pre_phase_head` before the phase's first commit, ported `requires_test_delta` (nominated test must exist, be non-empty, and have changed since `pre_phase_head` or be newly untracked/added), and made `complete_phase_success` reject with exit 5 + `requires-test-missing` after the gate but before the approve/reset side effects. · Proof: marathon-drive 112/0, marathon 33/0 (both modes); functional smoke — `--requires-test` on an UNCHANGED test now escalates `requires-test-missing` under Python (was a false exit-0 approval). No suite test exercises this; Codex found it by reading the Bash source.

**Relay outcome:** 4 rounds, **7 real findings total (1 Blocker in r2, 1 Blocker in r4, 5 Shoulds), ALL Implemented and verified.** Branch stays green (Python 117/117, Bash 116/117). Escalated to the operator per the cap: re-open for a confirming Codex round, or accept as QA'd.

### Reviewer · codex · Round 5

- [Should] `marathon_drive.py` still omits the Bash lifecycle-heartbeat contract: Bash writes the heartbeat immediately before driving the relay and clears it on every terminal success/failure path (`relay-automation/marathon-drive.sh:719`, `relay-automation/marathon-drive.sh:867-886`, `relay-automation/marathon-drive.sh:947-979`), while the Python port starts the relay directly and all of its terminal branches only emit completion telemetry (`utils/py/marathon_drive.py:528-533`, `utils/py/marathon_drive.py:663-789`). Under `XYZ_PYTHON=1`, the heartbeat is never created for a live phase and an existing one is never cleared, producing false/stale operational liveness. Fix: port `xyz_marathon_heartbeat_write`/`xyz_marathon_heartbeat_clear` (including the context/session routing and best-effort behavior), call write before the relay drive, and call clear in each terminal branch before completion telemetry.

Verdict: Changes requested. Round cap reached; escalated for operator replan.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
