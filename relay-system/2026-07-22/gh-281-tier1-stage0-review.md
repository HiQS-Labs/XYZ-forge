# RELAY · GH-281 Tier-1 Stage-0 build review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-22.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

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
6. **Commit only the relay file** (`relay(gh-281-tier1-stage0-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-22
- **Artifact under review** — the GH-281 Tier-1 Stage-0 build now on branch `gh-281-sentinel-2026-07-22`
  (commit range `2889fbf..HEAD`). Read these files directly in your worktree:
  - `relay-automation/harvest-findings.sh` (new — extracts `### Side Finding` blocks → debug.log JSONL)
  - `relay-automation/finding-new.sh` (new — manual JSONL filer)
  - `relay-automation/hooks/sentinel-network-guard.sh` (new — CI guard: bundled scripts must be zero-network)
  - `test/sentinel-tier1.sh` (new — covers harvest + finding-new)
  - `test/sentinel-network-guard.sh` (new — covers the guard)
  - `.gitignore` (line 60: `debug.log`) · `validate.sh` (TESTS registration)
  - Context (do NOT re-review, treat as the spec): `PROJECT/2-WORKING/GH-281-SENTINEL-TIER1-STAGE0.md`
    and issue #281 §1.2–§1.7. The two capture scripts were built to VERBATIM issue source; the guard +
    both tests were designed to the acceptance checks.
- **Scope of THIS slice (do not fault it for these — they are deliberately out of scope):** the six
  §1.3 `marathon-drive.sh` driver hooks (orchestrator-only, self-edit hazard), Tier-2 (Gemma overlay,
  GitHub egress), and validate.sh full-suite is already green.

- **Definition of Done — grade the build against these, in priority order:**
  1. **Zero-network invariant (CONSTITUTION "no phone home" / issue §0).** Do the bundled scripts make
     ANY network call (`curl`/`wget`/`nc`/`gh`/`/dev/tcp`/`http`)? Is the guard's own scope honest —
     does its *default* set (the two capture scripts) actually enforce the invariant that matters, and
     is narrowing away from "all of relay-automation/" defensible given legit network users
     (`codex-turn.sh`, `marathon-drive.sh`'s `gh`)? Or is it too narrow to be meaningful?
  2. **Correctness / robustness.** The `harvest-findings.sh` awk parser: does it correctly flush on
     `###`/`#`/`---` boundaries, escape quotes/backslashes/tabs, and never fail a phase (best-effort)?
     `finding-new.sh` JSON escaping? Any input that produces invalid JSONL or drops/duplicates a finding?
  3. **PDDA output-contract fidelity (issue §1.2).** Do emitted lines match the
     `timestamp/severity/check/scope/repo/file/line/message/action/probe` shape with PDDA's
     `error|warn|info` vocab? Is finding-severity kept separate from doc-risk (not merged)?
  4. **Deterministic-before-LLM & verified-success-only (GUIDING-PRINCIPLES / CONSTITUTION).** Are the
     tests genuine (real fixtures, real assertions), or do they pass vacuously?
  5. **Skill-first / existing patterns (GUIDING-PRINCIPLES).** Does the guard follow the
     `relay-automation/hooks/security-scan.sh` + `test/security-scan.sh` precedent? Any reinvention
     where a shipped helper exists?
  6. **Measured-gap / DO-NOT-BUILD bar.** Does anything here add Bash/policy complexity beyond the
     measured gap, or drift toward a generic platform?
  Cite `file:line` or a quoted span for every finding. Grade `[Blocker]/[Should]/[Nit]/[Pass]`, then a
  single **Verdict** (Approved | Changes requested | Blocked). Reviewer does NOT edit — findings only.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
