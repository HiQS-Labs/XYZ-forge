# RELAY · HQ (GH-128) code review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-04.
-->

NEXT: Reviewer
STATUS: Open
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
6. **Commit only the relay file** (`relay(hq-gh-128-code-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: the **HQ command-center feature (GH-128)**, all committed on `main` at HEAD.
  Review these repo-relative paths (read them directly in the worktree; they are all present):
  - `skills/hq/find-hq.sh` — device-agnostic locator for `utils/hq/hq.sh`
  - `skills/hq/install.sh` — symlink installer into `~/.claude/skills/`
  - `skills/hq/SKILL.md` — the `/hq` front door + invocation contract
  - `utils/hq/hq.sh` — the dispatcher (resolve/status/registries/next/park/queue/fire)
  - `utils/hq/hq-lib.sh` — the resolver library (registry ladder, SQL lookups, fuzzy matching)
  - `test/hq.sh`, `test/hq-park.sh`, `test/hq-dispatch.sh`, `test/hq-next.sh`, `test/hq-locator.sh` — the hermetic suite
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-04
- Definition of Done — the Reviewer grades against these, most-severe first:
  1. **Correctness** — do the resolver ladder, fuzzy matching, dispatch gating (Tier A + `risk<3`),
     and the locator's 3-rung resolution behave as documented? Any logic that silently mis-resolves,
     mis-gates, or crashes on a degraded/missing registry?
  2. **Security** — SQL is built by string interpolation in `hq-lib.sh` (`hq_rebalance_lookup`,
     `hq_projects_by_priority`). Is the `hq_sanitize` defanging sufficient, or can a crafted project
     name inject? Any path-handling issue (unquoted expansions, `eval` of untrusted data, symlink
     traversal in `find-hq.sh`, the `--env` eval surface)?
  3. **Shell portability** — bash 3.2 (macOS default): any `readlink -f`, associative arrays,
     `${var,,}`, process-substitution, or GNU-only flags that break on stock macOS?
  4. **Guardrail integrity** — does `fire` truly never drive the harness (only emits `swarm-preflight`)?
     Are write paths (`park`/`queue`) genuinely preview-by-default? Is Rebalance strictly read-only?
- Scope note: this is a **review-only** turn — report graded findings + a Verdict; do **not** edit code
  (the turn's ALLOW_PATHS is empty, so any code edit is reverted). Reading any path is fine.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
