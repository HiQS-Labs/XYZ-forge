# RELAY · GH1092 additional remediation FINAL round 3 carryforward
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-12.
-->

NEXT: done
STATUS: Approved
ROUND: 3 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1092-remediation-r3): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: relay-automation/relay-turn-lib.sh; skills/1-hourly/relay-xyz/SKILL.md; existing relay-pkg.tar.gz
- Reviewer: codex   ·   Producer: implementation
- Started: 2026-11-12
- Definition of Done: Answer the Producer Round 3 questions below against the exact pinned candidate; do not edit source.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 3

This is the explicitly authorized ADDITIONAL remediation review, carrying forward the final
remaining turn of the original three-round FINAL budget. Original gh1092-final.codex.md remains
closed Approved round2, with all text/attestation untouched. No reset of earlier attempts or
tokens: shipped utils/py/relay_drive.py treats a done token as spent and instructs a fresh task;
it has no documented reopen flag. Exactly ONE --review-once dispatch here, no further retry.
Candidate MUST be 32c838c80d6a7c80aa1f1d8552fa26a26e4c3050; record actual worktree HEAD and
immutable SHA256 of both complete touched sources and package. No source edits, pushes,
merges, installs, delegates or additional Kimi. ALLOW_PATHS empty; relay only; isolation on.

Read original FINAL and PLAN relays, additional Kimi advisory gh1092-additional.kimi.md,
PROJECT/2-WORKING/GH-1092-REVIEWER-EVIDENCE.md, complete touched source files and diff,
TESTS-RESULTS/2026-11-12+GH-1092/SUMMARY.md, provenance and git-inspection-fix/ receipts.
Operational envelope: local operator CLI, bounded prompt permission/docs/package fix only.
Kimi configured-high advisory at 551531fa and CodeRabbit4556715114 found S1: identity commands
required but later NEVER git. Parent fixed itself in 1d749cf73 with explicit read-only local Git
allowance and mutating Git prohibition; package rebuilt. Evidence-only candidate 32c838c80 adds
focused gh681 allpass and complete identity brackets. CodeRabbit4556715121 noted old identity
snapshots lack core.bare/full remote-v; historical missing fields are unavailable, not fabricated.
Kimi CLI high actual relay unsupported: advisory is NOT supervisor attestation.

Questions:
1. Is S1 fixed? ACTUALLY invoke narrow read-only local Git identity commands in this isolated
review worktree and quote each command, exit and decisive output: git rev-parse --show-toplevel;
git rev-parse HEAD; git remote -v; git config --get core.bare; git config --local --get user.name;
git config --local --get user.email. Unset fields may exit 1; report honestly. Retain mutating ban.
2. Any prompt injection, role, containment regression or source/package mismatch? Read complete
sources; compare archive bytes without extraction outside scratch. No containment code change claimed.
3. Is historical identity limitation honestly disclosed and the new complete bracket sufficient?
4. Are all original GH981 eight findings, broader1092 open scope and no runtime/browser claim retained?
5. Is change surgical with no unnecessary machinery? Give file:line evidence and original observed
input/affected scope/falsifier for any Should/Blocker requesting behavior change.

Prior 408/408 full gate at 70ebdeb4 is HISTORICAL ONLY. Parent runs new full classified gate
AFTER this review approval on revised source. Pending gate is not automatic code finding.
Baseline controls lexical only: do not pretend live reproduction of every original failure.
No suite execution assigned this turn; focused current producer receipts are supporting evidence.
Record VERDICT PASS/FAIL/PARKED, Basis, swept-file yes/no. Only harness commits relay artifact.
On approval close token and STATUS Approved; on nonapproval hand to implementation and escalate
at round3/3. Parent owns small fixes. Final handoff must state parent action and retained limits.

### Reviewer · Round 3

VERDICT: PASS
Basis: S1's conflicting Git instructions are repaired at the exact required candidate. Actual read-only Git probes succeed (unset local identity is reported honestly), package bytes match, and the new complete identity bracket supports the focused producer receipt without repairing history retrospectively. Approve this bounded prompt/docs/package remediation for the parent's fresh classified gate; no runtime qualification or issue closure is conferred.
swept file: yes

Target: XYZ Forge, parent checkout `/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh1092-reviewer-evidence-2026-11-12`; resolved review root `/private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/rtl-wt.GfwtWa`; actual reviewed HEAD `32c838c80d6a7c80aa1f1d8552fa26a26e4c3050`. Rules consulted: `ROUTER.md`, supplied/local `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `SOP.md`, `WORKTREE-SAFETY.md`, `HARNESS-MODELS-REGISTRY.md`, `TESTS-RESULTS/README.md`, and the active GH1092 plan. Applied relay-xyz/SWE guidance. Target test policy is Forge GH831's no-new-suite rule and disposable-full-clone execution for mutation-heavy checks. This round explicitly assigns no suite execution; prior-round clone assignments are historical, not authorization to rerun them here. Foreign targets retain their own policy.

- [Pass] S1 resolved in delivered instructions: `relay-automation/relay-turn-lib.sh:1172` now explicitly permits “Read-only local Git inspection” and forbids “state-changing Git commands”, including checkout/fetch and config/remote writes. The actual received prompt contains that same distinction. The before/after identity requirement at `:1067` is therefore compatible with ordinary read-only inspection. No mutation permission is inferred. Actual probes below exercise the previously contradictory operation, rather than treating wording alone as runtime proof.

Read-only identity probe results (each command invoked through Python `subprocess.run(args, capture_output=True, text=True)` in this isolated review root; all stderr empty):

| Command | Exit | Decisive output |
|---|---:|---|
| `git rev-parse --show-toplevel` | 0 | `/private/var/folders/z0/92pfvhnn06z2_7hnpdb4kkbw0000gn/T/rtl-wt.GfwtWa` |
| `git rev-parse HEAD` | 0 | `32c838c80d6a7c80aa1f1d8552fa26a26e4c3050` |
| `git remote -v` | 0 | `origin https://github.com/HiQS-Labs/XYZ-forge.git (fetch)` and `origin https://github.com/HiQS-Labs/XYZ-forge.git (push)` |
| `git config --get core.bare` | 0 | `false` |
| `git config --local --get user.name` | 1 | empty; unset |
| `git config --local --get user.email` | 1 | empty; unset |

- [Pass] Whole-file/source/package sweep: read all 1,826 lines of `relay-turn-lib.sh` and all 767 lines of the relay-xyz skill, original PLAN/FINAL relays, additional Kimi advisory, active plan, SUMMARY/provenance and git-inspection-fix receipts. `git diff ed0a386fac4caa170bd9d6b297da7154717288df..HEAD -- relay-automation/relay-turn-lib.sh skills/1-hourly/relay-xyz/SKILL.md` (exit 0) shows only the reviewer note, shared final Git instruction, and existing item-5 mirror. No prompt-injection, role or containment regression, additional relevant pre-existing defect, or unnecessary machinery found in this sweep. Reviewer role derivation/allowlist at `relay-turn-lib.sh:66-115,358-368`, artifact signature enforcement at `:920-930`, and enforcement/writer at `:1494-1826` are unchanged. The producer verification clause at `:1043` remains; GH1428's named phase exception remains at `:1067`. This is static assessment, not a new adversarial/runtime containment result.
- [Pass] Immutable hashes measured with `shasum -a 256 relay-automation/relay-turn-lib.sh skills/1-hourly/relay-xyz/SKILL.md skills/1-hourly/relay-automation/relay-pkg.tar.gz` (exit 0): respectively `106dbe113a81a857c413df98bcdba01fb0b791ec4b89b3504a7e141f426bc183`, `fa5aaec648c8a45fea6d1c5305023feb07a1707f3ff8245726bab071b9dd4997`, `c5753038841f520c01bd4b76e2ed5146a0d6e7ec9391e3da1866d09c64e72234`. Read-only Python `tarfile.open(package); b=t.extractfile('relay-automation/relay-turn-lib.sh').read(); assert b and b == Path('relay-automation/relay-turn-lib.sh').read_bytes()` (exit 0) printed `nonempty archive shared library equals current source: True`; no extraction to disk. A separate member-by-member byte comparison found 18 regular archive members with existing source paths and `mismatches []` (exit 0).
- [Pass] Historical limitation honestly retained: `SUMMARY.md:88-94` explicitly says historical configured core.bare/full remote listings are unavailable, the old bracket is incomplete, and prior 408/408 belongs only to its recorded revision. That appended qualification supersedes the earlier frozen checkpoint's broader identity wording; it does not reconstruct absent evidence. `git-inspection-fix/identity-before.json` and `identity-after.json` contain equal root, HEAD `1d749cf738858b084816e1d11c61a6153e2ffcef`, both origin/task fetch/push listings, configured core.bare=false, and local identity unset with exit 1. Those fields are sufficient for the required complete bracket of that focused run. `focused.log` ends “gh681-reviewer-probe-rules: all cases passed”, including scratch-only acceptance and forbidden `.pytest_cache/` rejection. This is inspection of producer evidence, not my execution of that suite or a bracket for candidate 32c838c80's future gate. Kimi remains configured-high advisory, not supervisor-attested (`SUMMARY.md:90`).
- [Pass] Scope continuity: `PROJECT/2-WORKING/GH-1092-REVIEWER-EVIDENCE.md:106-128` retains six decisions' unimplemented predicates, all original eight GH981 findings, and `75/70/50/65, no override`. `SUMMARY.md:39-50` preserves both issues, proposed/not-adopted owner recommendations and actual app/copied-storage/native-navigation/126-second replay as outstanding. Baseline delivery rejection remains lexical; original FAIL/PARKED turns remain unchanged. Neither this correction nor package matching establishes browser safety, global policy ratification or all-model compliance.
- [Unverified — needs clone run] No suite, pytest, executable fixture or full gate ran in this turn. The fresh route=full/tier=3 gate on revised source remains the parent's next action after approval, with complete before/after identity fields. Prior 408/408 is historical only. No clone creation, source edit, Git mutation, delegation, push, merge, installation or browser replay performed. Final containment/attestation is the harness's post-turn responsibility, not claimed from these probes.

Relay closed (Approved), no further turn needed. Parent: run the fresh classified gate on the approved revised source, retain the complete identity bracket and historical limits, and block publication on gate failure; broader GH1092/GH981 requirements remain open. Harness owns the relay-only commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
