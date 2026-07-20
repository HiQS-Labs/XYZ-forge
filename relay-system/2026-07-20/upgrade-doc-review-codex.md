# RELAY · UPGRADE.md QA — independent Codex pass
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 5

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

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
