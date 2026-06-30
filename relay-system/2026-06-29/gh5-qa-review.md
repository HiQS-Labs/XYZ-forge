# RELAY · GH-5 QA review (pdda issue-doc-sync + doc-health hooks)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-29.
-->

NEXT: —
STATUS: Approved
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh5-qa-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/gh5-review-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-pdda/70e7a6fd-f0ef-4130-8634-f0eccc2042e2/scratchpad/gh5-review-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-06-29
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · agy · 2026-06-29
**Verdict:** Approved
**Basis:** verified the unified diff under review (`.relay-artifacts/gh5-review-packet.md`) and unit test specifications.

**Findings:**
- **[Pass] Two-tier hook fail-open design**: Both hooks (`PostToolUse` edit hook and `Stop` full-scan hook) are explicitly designed to exit `0` under all conditions, ensuring doc-hygiene linting never interrupts the developer's work or blocks a git/harness operation.
- **[Pass] Safe and portable issue-state caching**: The introduction of `pdda-gh-refresh.sh` allows the `Stop` hook and `issue-doc-sync` check to run completely offline without querying GitHub via network, preventing slow responses or API rate-limiting issues. The caching mechanism is atomic (via temp file and `mv`).
- **[Pass] Fine-grained status matching**: The `_pdda_status_leadword` implementation prevents false-positives by anchoring only on the first word of the status line (e.g., `Active — Phase 0 complete` correctly resolves to `active`, avoiding a false `complete` trigger).
- **[Pass] Scoped linting via `PDDA_ONLY_FILE`**: Tier 1 hook uses the `PDDA_ONLY_FILE` seam to limit linting to the single edited doc, keeping it fast and lightweight.
- **[Pass] Extensive test suite coverage**: Excellent coverage in `test/pdda-issue-doc-sync.sh` and `test/pdda-doc-health-hooks.sh` that validates fail-open behavior, drift matching, degraded modes, and file-based fallbacks.
- **[Nit] `_pdda_doc_issue_number` fallback support for `GH-<number>.md` filename**:
  If a working doc has no `gh_issue` key and is named exactly `GH-<number>.md` without a description (e.g. `GH-101.md`), the regex match `GH-[0-9]*` matches, leading to `num="101.md"`. The `grep -Eq '^[0-9]+$'` check then fails, preventing issue resolution for that file.
  *Fix (suggested, not required)*: We could strip the `.md` extension before the regex check, or use `num="${num%%.*}"` before `num="${num%%-*}"`.

The implementation meets all guidelines and principles. Approved.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
