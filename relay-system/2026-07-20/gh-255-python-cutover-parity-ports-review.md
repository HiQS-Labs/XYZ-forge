# RELAY · GH-255 Python cutover — parity ports review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-20.
-->

NEXT: codex
STATUS: Open
ROUND: 3 / 4

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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
