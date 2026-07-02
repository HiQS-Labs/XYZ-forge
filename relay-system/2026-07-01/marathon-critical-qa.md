# RELAY · Marathon queue drive (GH-74/71/69/64) — critical-path QA
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifacts named in Setup (read the real files as they exist in this checkout; cite `file:line`):
   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit any artifact; you only append findings here.
   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line (`<!-- ↓↓↓ NEXT TURN ... -->`). Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**` (or `none — review only`).
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`).
6. **This is a REVIEW-ONLY turn — do not edit the artifacts.** Only this relay log file may be touched. Commit only this file: `git commit -m "relay(marathon-critical-qa): <your-label> r<N>"`, then put the short hash in your block's `Commit:` line and `git commit --amend --no-edit`.
7. **Stop.** Tell the operator your one-line result (e.g. "Changes requested, 1 Blocker — awaiting operator disposition").

## Setup
- Artifacts under review (as committed on `main`, in this checkout):
  1. `relay-automation/hooks/security-scan.sh` — the baseline-suppression mechanism added this session (`USE_BASELINE`, `baseline_hit()`, `BASELINE_FILE`, `--no-baseline`, `--tsv`, the `_check()` accounting split between `FINDINGS`/`BASELINED`)
  2. `relay-automation/hooks/security-scan-baseline.txt` — the checked-in baseline data itself (45 entries)
  3. `utils/swarm-preflight.sh` — the branch-suggestion + carve-out logic added this session (`SUGGESTED_BRANCH`, `BRANCH_READY`, the `FM_RISK`/`ZONE`/`SKIP_BRANCH_PROMPT` block, and every place those flow into `normalize.mjs`'s `provenance` object, the text report, and `packet.md`)
- Definition of Done: independently answer — for the security-scan baseline mechanism: (a) can the exact-match-by-content design be gamed to suppress a genuinely NEW malicious finding (e.g. by crafting text that collides with a baselined triple, or a matching bug in `baseline_hit()`/`_check()`)? (b) is any baselined finding in `security-scan-baseline.txt` actually NOT safe (a real credential/secret, not a doc comment or reviewed dispatcher pattern)? (c) does the scanner ever fail open (report clean when it shouldn't) on a real bug, not just a reviewed pattern? For swarm-preflight.sh's branch logic: (d) can `SKIP_BRANCH_PROMPT`/`BRANCH_READY` ever cause a branch to be auto-created or a destructive git operation to run (it should be read-only, `git show-ref` only — confirm no write path exists)? (e) is the re-derived `KERNEL_PATHS`/`ZONE` heuristic correct/consistent with `marathon-plan.sh`'s original, or could it misclassify a kernel-touching lane as `independent` (letting the carve-out wrongly skip the prompt on a HIGH-risk lane)? Flag anything else load-bearing you find along the way, graded normally.
- Producer: Claude   ·   Reviewer: agy
- Handoff: cli-driven (agy)
- Started: 2026-07-01

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top.
4. Stay tight. Requests and findings are bullets, not essays.
5. **The Reviewer never edits any artifact.** It proposes graded findings, each with a concrete suggested fix where possible. The Producer (with the operator) decides each proposal and implements the approved ones, logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding: `[Blocker]` must fix · `[Should]` strong recommendation · `[Nit]` optional · `[Pass]` checked and sound (records what was verified, not assumed).
7. The Reviewer posts a Verdict every turn.
8. End your turn by committing it: `relay(marathon-critical-qa): <role> r<N>`, then fill the hash into your `Commit:` line.
9. **One window at a time, clean tree at every handoff.**
10. **Evidence contract — state your proof every turn.** `Basis:` `behaviorally proven` (ran/observed, e.g. actually ran `security-scan.sh` against a crafted fixture) or `textual only` (read, not run).
11. This is a REVIEW-ONLY relay — the artifacts are already committed/pushed; the Reviewer reads them as they sit in the checkout. No `--artifact-file` seeding needed.

## Roles
- **Producer** — Claude: files this QA request, then (with the operator) decides and implements approved findings after the Reviewer's turn.
- **Reviewer** — agy: reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifacts.

---
## Log

### Round 1 · Producer · 2026-07-01 22:58 PT
**Did:**
- Shipped 4 items this session (GH-74 fix, GH-71 Phases 1-2, GH-69, GH-64) — see `CHANGELOG.md`'s "Marathon queue drive" entry (2026-07-01) for full context on all four.
- Scoped this QA pass to the two pieces of genuinely NEW logic with the highest blast radius if wrong: the security-scan baseline-suppression mechanism (could silently mask a real vulnerability if the matching logic has a bug) and swarm-preflight's branch/carve-out logic (novel zone-reclassification; must never have a write path).
- Self-caught and fixed one real bug already during development: the baselined-finding print originally dropped the matched line text (only showed file:line), weakening the "nothing is hidden" claim — fixed before committing. Also self-caught a `set -e`/pipefail script-killer in an earlier item (GH-74/GH-69 test authoring) — not in scope for this review, but noting the general pattern in case similar issues exist here.

**Review this:** see Definition of Done in Setup above (5 named questions, (a)-(e)).
**Verification:** `test/security-scan.sh` 28/28 (incl. a real-repo-against-baseline assertion), `test/swarm-preflight.sh` 44/44 (incl. 9 new branch/carve-out assertions), `validate.sh` 77/77, `pdda.sh run` clean — all at commit `a66bf9a` and later.
**Open questions:** see "Review this" above.
**Commit:** none — review only (this Producer block is the request; no artifact touched)

### Round 1 · Reviewer · agy-findings · 2026-07-01 23:10 PT

VERDICT: FAIL
Basis: behaviorally proven and textual only

**Findings & proposals:**
* [Blocker] **Credential Scan Exclusion Fail-Open Vulnerability**: In `relay-automation/hooks/security-scan.sh`, the line-level exclusion logic (`grep -vE -e "$exclude"`) removes the entire matched line from findings. If an attacker appends a comment matching the exclusion pattern (e.g. `# password=$VAR`) or places a variable reference on the same line as a hardcoded secret, the entire line is bypassed.
  * *Proposed Fix:* Refactor the scanner to match and check credentials individually on the line/field level rather than applying regex-based line exclusions, or do not allow comments to act as exclusions.
* [Should] **Grep/Read Errors Fail-Open**: In `relay-automation/hooks/security-scan.sh`, `grep -nE -e "$pattern" "$f" 2>/dev/null || true` swallows grep execution errors (exit status 2). If grep fails (e.g., file permissions or system errors), the script silently ignores it and reports the file as clean.
  * *Proposed Fix:* Capture the exit status of `grep`. Accept `0` (match) and `1` (no match), but fail loud on any other exit code.
* [Should] **Discrepancy in Kernel Zone Classification**: In `utils/swarm-preflight.sh`, the kernel zone check is an exact match (e.g., `bin/tick`), whereas in `utils/marathon-plan.sh` it uses a prefix match (`startsWith`). A kernel-adjacent script like `bin/tick-helper.sh` is classified as `kernel` in `marathon-plan.sh` (blocking) but as `independent` in `swarm-preflight.sh`, which wrongly skips the operator prompt.
  * *Proposed Fix:* Align the matching logic in `utils/swarm-preflight.sh` to match `utils/marathon-plan.sh`'s `startsWith` logic.
* [Nit] **Discrepancy in Case-Sensitivity of Shim Matching**: Shim matching in `utils/swarm-preflight.sh` is case-sensitive, but case-insensitive in `utils/marathon-plan.sh`. A path like `relay-automation/Codex-turn.sh` would bypass shim classification in `swarm-preflight.sh` and be treated as `independent`.
  * *Proposed Fix:* Enable case-insensitive matching in `swarm-preflight.sh`.
* [Pass] **Strict Literal Baseline Matches**: Verified that `baseline_hit` in `relay-automation/hooks/security-scan.sh` performs exact literal string matches (`[[ "$btext" == "$text" ]]` with quoted rhs), preventing any accidental wildcard/regex matches.
* [Pass] **Preflight Git Operations are Read-Only**: Confirmed that `SKIP_BRANCH_PROMPT` and `BRANCH_READY` paths only execute read-only Git commands (`git show-ref`, `git symbolic-ref`, etc.). No branch writing or destructive operations exist.

**Commit:** none — review only (harness-committed after handoff)

<!-- ↓↓↓ NEXT TURN GOES HERE — append below this line, do not edit above ↓↓↓ -->


