# RELAY · GH-943 independent QA — loader-limit trims + merge-cleanup batch-issue protocol
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 2

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
6. **Commit only the relay file** (`relay(gh943-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh943-relay-diff.patch** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/XYZ-forge/temp/gh943-relay-diff.patch` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: claude   ·   Producer: claude-a
- Started: 2026-10-02
- Definition of Done: PR #943 (branch fix/gh-942-skill-desc-1024-limit, commits e728e741+4d66ab89) is independently QA-clean:
  (a) the three trimmed skill descriptions fold to <=1024 chars while preserving trigger phrases and exclusions;
  (b) the merge-cleanup batch-issue protocol is internally consistent with the existing drive loop, Phase C ladder, and parity-guard capability table, and contradicts no repo rail (GH-831 no-new-tests, GH-564 disposable-clone, containment);
  (c) ledger/pointer-doc changes are sane;
  (d) nothing weakens an existing safety guarantee.
Operational envelope: local developer CLI skill docs (XYZ-forge). Commensurate complexity — no enterprise threat models. XYZ-forge policy: NO new test suites is CORRECT there (GH-831); asking for one is itself a finding.

## Reviewer questions (answer each, with file:line or quoted spans)
1. Fold-count each trimmed description in the diff (radar, 10days, express, merge-cleanup): is any still over 1024 folded chars? A read-only python probe under $TMPDIR is allowed (GH-681).
2. Do the trimmed descriptions keep the trigger phrases front-loaded and the "not for" exclusions? Name any loss that would break skill-consumer matching.
3. Is the "Batch issue protocol (GH-944)" section consistent with the drive loop, the Phase C caller ladder, and the capability table (caller-owned rows only; no script changes; CLI option list untouched)? Cite any contradiction.
4. Does the protocol keep issue-posting non-blocking and containment intact? Does anything in the diff weaken an existing safety guarantee?
5. Are the two pointer docs and the releases.sql roadmap rows consistent with the issues they capture?
6. Commensurate complexity: flag over- or under-engineering anywhere in the diff.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (claude)

swept file: no

No review of PR #943 was performed this turn. The artifact was not seeded into this worktree, and
the session ran out of budget before a fallback read was possible. Nothing below is a judgement on
the diff itself; reviewer questions 1-6 are all unanswered.

- **[Blocker] Artifact named in Setup is absent from the isolated worktree.**
  Command (from worktree root): `wc -lc .relay-artifacts/gh943-relay-diff.patch` →
  `wc: .relay-artifacts/gh943-relay-diff.patch: open: No such file or directory`; the fold-count
  probe then died with `FileNotFoundError: [Errno 2] No such file or directory:
  '.relay-artifacts/gh943-relay-diff.patch'` (rc=1).
  `ls -la .relay-artifacts` shows exactly one file, from a different relay:
  `gh182-claim-guards.md  24.2K`.
  The seed source does exist: `/Users/noelsaw/Documents/GH Repos/XYZ-forge/temp/gh943-relay-diff.patch  32.1K`.
  Observed input: this worktree's `.relay-artifacts/` holding `gh182-claim-guards.md` instead of `gh943-relay-diff.patch`.
  Affected scope: any `relay-drive.sh --artifact-file` run whose worktree ends up with a stale or foreign `.relay-artifacts/`.
  Falsifier: re-seed and run `ls .relay-artifacts/gh943-relay-diff.patch` in the reviewer worktree — if it lists the 32.1K patch, this finding is cleared and was a one-off seeding miss.
  Fix: re-run the driver so the gh943 patch is actually seeded (or re-point Setup at a path that exists in the worktree), then re-fire the Reviewer turn. No artifact change is requested of the Producer.

- **[Unverified — not reviewed] DoD (a)-(d) and reviewer questions 1-6.** The 1024-char fold counts
  were never measured (the probe did not run against any input). Protocol consistency, containment,
  ledger/pointer-doc sanity, and safety-guarantee checks were not started. I did not read the patch
  from the source path outside the worktree: the session budget could not cover a whole-file read of
  a 32.1K diff plus the skill files it touches, and a partial read would not support a verdict.

- Pre-existing defects in the touched files: not swept, so none can be reported either way.

**VERDICT: PARKED**
**Basis:** The review could not start — the seeded artifact is missing (a foreign gh182 file sits in
its place) and the reviewer session's budget was exhausted before a fallback. This is a harness /
seeding problem, not a finding against PR #943. The round is consumed without a review; the next
Reviewer turn needs the artifact present and a fresh budget.

Handing off to Producer (claude-a) — go to the Producer window and say "take your turn": re-seed
`.relay-artifacts/gh943-relay-diff.patch`, log a disposition for the Blocker, and return the turn
to the Reviewer. No change to the diff is being asked for.

### Producer · Round 1 (claude-a)

- **[Blocker] Seeded artifact missing** — Implemented (driver invocation fix, no artifact change):
  the Round-1 drive call omitted `--artifact-file`, so `relay-drive.sh` never seeded the worktree —
  `.relay-artifacts/gh182-claim-guards.md` is a pre-existing tracked leftover in the repo, not this
  relay's seed (falsifier confirmed from the Producer side: the source patch exists at
  `temp/gh943-relay-diff.patch`, 32.1K). Re-fired with `--artifact-file` so the fresh worktree seeds
  `gh943-relay-diff.patch`; the Reviewer's own falsifier check (`ls .relay-artifacts/gh943-relay-diff.patch`)
  should now clear it.
- Reviewer budget for Round 2 raised so the whole-file read correctly declined in Round 1 is
  affordable within the turn.
- No change requested or made to the reviewed diff (PR #943 commits e728e741+4d66ab89 unchanged).

Handing off to Reviewer (claude) — take your turn with the seeded artifact.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
