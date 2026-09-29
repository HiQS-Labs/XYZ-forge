# RELAY · GH-856 locator plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-29.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-856-locator-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-856-RELAY-LOCATOR.md`.
- Read the full issue at https://github.com/HiQS-Labs/XYZ-forge/issues/856 and the current source in `skills/1-hourly/relay-xyz/find-harness.sh`, `relay-automation/harness-paths.sh`, and the registered `test/find-harness.sh` and `test/gh396-find-harness-roots.sh`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-29
- Definition of Done: the plan names the real failure path, preserves existing locator precedence, gives a minimal implementation that works for copied Skills Army deployments, and includes falsifiable checks for ambiguous clones, stale upstream, loaded lock resolver, and existing vendored behavior. The work stays within the existing locator and registered suites; AGENTS.md forbids new suites.

### Questions for this plan review

1. Do the cited source paths and observed commands support the root-cause statement? Identify any wrong claim with a file:line citation.
2. Does the plan meet every actionable requirement in #856 while preserving the #394/#395/#396 contracts? Name any concrete missing input or state.
3. Is the config/search fallback ordered correctly, especially when a caller has `.xyz`, a worktree has a parent `.xyz`, or the current repo is itself a harness?
4. Are the acceptance controls capable of going red before implementation and green afterward? Name any vacuous check.
5. Is the proposed scope commensurate with a local Bash locator? Flag a simpler way to use an existing helper, or unnecessary machinery.

Operational envelope: this is a local CLI locator for one repository family, across four Macs. Grade against that scope. Do not request a general plugin registry, network discovery service, or unrelated root-resolution refactor. Review only; write findings to this relay file.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

- [Should] The fallback roots are not enumerated in the plan (`PROJECT/2-WORKING/GH-856-RELAY-LOCATOR.md:50`), so a build can pass one search fixture while still missing a reported Mac. Name the exact bounded roots from #856 and pin each observed spelling in the registered suite, including `~/Documents/GH Repos/XYZ-forge`, `~/Documents/GitHub/XYZ-forge`, `~/Documents/GitHub Repos/XYZ-forge`, and `~/Documents/GitHub-Repos/XYZ-forge`. Concrete fix: list the roots and require a red-before/green-after copied-skill lookup for each.
  Observed input: #856's per-Mac table reports those four different canonical clone paths; the deployed skill exits 1 from `~` on the surveyed Macs.
  Affected scope: copied skill, no override or usable caller harness, no config, with exactly one canonical clone in a documented search root.
  Falsifier: for each listed root, a fixture containing only an origin-validated `XYZ-forge` there must resolve it as `via=search`; a root omitted by the implementation must fail that fixture before the fix.
- [Should] The no-candidate failure contract is too vague: step 4 says only “actionable failure message,” and acceptance omits the issue's required list of attempted paths and runnable remedy (`PROJECT/2-WORKING/GH-856-RELAY-LOCATOR.md:53-62`). Pin an exact no-config/no-candidate assertion in an existing suite, including exit 1, attempted locations, and a quoted `XYZ_HARNESS` or config remedy; verify it goes red on today's message at `skills/1-hourly/relay-xyz/find-harness.sh:179-182`.
  Observed input: #856's `cd ~ && env -u XYZ_HARNESS -u XYZ_REPO_ROOT ... --check` exits 1 and says only `Set XYZ_HARNESS=/path/to/your/xyz-3-agents-swarm clone and retry` (`find-harness.sh:180-182`).
  Affected scope: every lookup that exhausts override, vendored, current-root, self-relative, config, and bounded search candidates.
  Falsifier: an isolated copied-skill fixture with no candidate exits 1 and prints every attempted location plus a runnable remedy naming `XYZ-forge`; a fixture with one valid candidate still resolves it.
- [Pass] Root-cause trace matches source: self-relative loading is at `find-harness.sh:103-107`, self-relative selection at `:169-177`, and the unchecked lock call at `:343-347`; `relay-automation/harness-paths.sh:25-32` sources the shared lock library.
- [Pass] The proposed order at `PROJECT/2-WORKING/GH-856-RELAY-LOCATOR.md:50` preserves the existing override → caller `.xyz` → main-worktree `.xyz` → git-root → self order in `find-harness.sh:122-177`; `test/gh396-find-harness-roots.sh:149-185` pins the override, vendored, git-root, and self cases. A current harness repo and a caller or parent vendored `.xyz` therefore retain priority over config/search as written.

VERDICT: FAIL
Basis: The diagnosis and precedence are sound, but the plan does not yet make the four observed search roots or the required no-candidate diagnostic falsifiable. The whole plan file was swept; no other issue found.

Handing off to Producer — go to the Producer window and say “take your turn”.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
