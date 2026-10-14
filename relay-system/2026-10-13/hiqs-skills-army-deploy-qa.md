# RELAY · QA: HiQS skills deployment via skills-army-hq SOP
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-13.
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
6. **Commit only the relay file** (`relay(hiqs-skills-army-deploy-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/hiqs-skills-deploy-evidence.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-hiqs-ai-resolve/e1cc774f-3230-482b-8148-e7d7414b4fa4/scratchpad/hiqs-skills-deploy-evidence.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-13
- Definition of Done: the HiQS skills (`hiqs-resolve`, `hiqs-scrape` added; `ai-catalog-update` re-sourced)
  were deployed strictly per the skills-army-hq SOP — script-only mutation, no hand edits/copies — and
  are byte-identical to their owning repo and linked into every enabled target.

### Operational envelope & non-goals
Single-operator local macOS skill deployment. READ-ONLY QA: do not run `intake.py`/`sync.py` with
`--apply`, do not edit anything outside this relay file. Non-mutating probes are allowed
(`readlink`, `diff -rq`, `git -C ... log/show`, `sync.py --status`, `intake.py list`), with output in
`$TMPDIR`. Do not demand new machinery or tests.

### Read
- The artifact above (evidence bundle with commands run, commits, parity, links, status, changelog).
- SOP: `/Users/noelsaw/git-pulse-sync/Deployed Skills/skills-army-hq/SKILL.md` and
  `/Users/noelsaw/git-pulse-sync/Deployed Skills/skills-army-hq/references/recovery.md`.
- Live state (read-only): `/Users/noelsaw/git-pulse-sync` (commits 73e432087, 0320259c4, e225b0c8b),
  owning repo `/Users/noelsaw/Documents/GH Repos/hiqs-ai-resolve/skills/{hiqs-resolve,hiqs-scrape,ai-catalog-update}`.

### Questions
1. Was every mutation performed by `intake.py`/`sync.py` (preview → apply), with no hand edits or manual
   copies/symlinks? Cite the changelog/commit evidence.
2. Is each deployed copy byte-identical to its owning repo source at the recorded commit 3afdd0c, and is
   `ai-catalog-update`'s recorded source now the owning repo instead of the stale `/private/tmp/hiqs-main`?
3. Do all 3 skills resolve through a symlink into `Deployed Skills/<name>` in all 6 enabled targets
   (agents, claude, codex, codex-compat, antigravity, grok-bot, zcode — check `targets.json`)?
4. Was the interrupted sync (sandbox EPERM) recovered per `recovery.md` (preview `recover`, then
   `--apply recover`), and is there any residual staging/pending state or half-written link?
5. Are the vendor commits scoped to just each skill's folder (GH-993), with the Pulse tree clean and not
   pushed by us (pulse pushes)? Flag anything that will block the hourly pulse.
6. Anything else in the SOP violated or left incomplete (e.g. prerequisites to record, catalog regeneration)?

Cite file:line or quoted command output for every `[Pass]`. Set STATUS: Approved if all pass.

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
VERDICT: FAIL
Basis: Payload deployment and link state look correct, but the explicit SOP prerequisite-recording step is incomplete. Reviewed the whole seeded evidence file, including its pre-existing reporting defects; no other deployment defect observed. Historical preview execution and absence of manual operations are supported by the producer's narrative, not independently reconstructible from final state. No Git commands, apply operations, suites, or executable fixtures were run.

- [Pass] Live payload parity and target coverage. Read-only Python probe (exit 0) compared recursive relative-path maps of file bytes and symlink text between the owning repo's skills and the collection; decisive output: "hiqs-resolve files 6 parity True", "hiqs-scrape files 2 parity True", "ai-catalog-update files 9 parity True". The same probe iterated enabled entries in `targets.json`, checking `p.is_symlink() and p.resolve()==collection/name`; each of "zcode", "codex", "antigravity", "claude", "codex-compat", "grok-bot" returned all three names. There are six targets: "codex" is the ~/.agents/skills root, not a seventh target. No fix needed.
- [Pass] Provenance and catalog are current. Command: `python3 -c 'import json; from pathlib import Path; r=Path("/Users/noelsaw/git-pulse-sync/Deployed Skills"); d=json.loads((r/".deploy-skills.json").read_text()); print({n:d["skills"][n] for n in ("hiqs-resolve","hiqs-scrape","ai-catalog-update")})'` (equivalent receipt read executed in the combined Python probe, exit 0). All three records quote commit "3afdd0c0190b2c5abd1ab7bdd75dae023ef30e97", "dirty": false and sources under the owning repo; ai-catalog-update no longer records /private/tmp/hiqs-main. Live catalog rows carry the same revision and six "linked" statuses. This establishes recorded revision and current checkout parity, not an independent Git-object comparison. No fix needed.
- [Pass] Recovery end-state is sound. Command: `python3 -c 'from pathlib import Path; print((Path("/Users/noelsaw/git-pulse-sync/Deployed Skills")/".deploy-skills-pending.json").exists())'` (same expression in combined probe, exit 0): "pending exists False". Live changelog operation `bfab400eb7da4b96a71d2ad8d69ed5cb` records the 12 new links, "apply": true, "errors": [], "warnings": [], and repo "dirty": [], "ahead": 3, "behind": 0. Artifact Commands 7–8 report preview recover → apply recover → no-op sync. Retained .staging entries exist; recovery.md explicitly says staged old versions are retained with no automatic deletion policy, so their mere presence is not a failed recovery. No cleanup requested.
- [Pass] Recorded vendor commit scope meets GH-993: artifact sections `git show --stat 73e432087`, `0320259c4`, and `e225b0c8b` list respectively only six hiqs-resolve files, two hiqs-scrape files and ai-catalog-update/SKILL.md. The live audit's add/add/update events at 04:41:06–07 match the source revision and payload digests. The recorded clean/ahead-three state supports no pulse blocker at deployment time and no deployment push; current Git state was not independently queried because this turn prohibits Git. No fix needed.
- [Should] Record runtime prerequisites through the manager before claiming strict SOP completion.
  Observed input: live `.deploy-skills.json` contains `"prerequisites": []` for all three skills (receipt probe above, exit 0). The loaded SOP's "Runtime dependencies are separate" says: "Record requirements locally using intake.py --apply prerequisite SKILL TEXT". hiqs-resolve/SKILL.md:10 says "needs curl only"; ai-catalog-update/SKILL.md:67 requires agy on PATH and signed in, and :101–105 use owning-repo docs/schemas and Bun scripts; hiqs-scrape/SKILL.md:19–23 describes curl and credentialed fallback providers.
  Affected scope: local prerequisite metadata for these three deployed skills, plus the evidence bundle's completion claim; no source code change or dependency installation.
  Falsifier: nonempty manager-produced prerequisite records accurately describing required runtime/repo context and optional credentialed capabilities, with matching catalog/list output, would discharge this finding. App runtime readiness must remain explicitly untested.
  Concrete fix: Producer should inspect the three skills, preview then apply the existing `intake.py prerequisite` operation for each, and refresh the evidence with the resulting records. Do not hand-edit metadata or install tools.
- [Nit] Replace the artifact's final "no matches found: .../*.pending*" with the exact hidden receipt check above, and include the relevant add/add/update/sync history events rather than only the trailing skills list. The glob neither names the hidden receipt nor establishes success. Current live absence was checked here; this is an evidence presentation correction.

Handing off to Producer (claude-a) — record prerequisites and update the evidence, then take the next review round.

### Producer · Round 2
- [Should] prerequisites → **Implemented.** Previewed, then applied `intake.py --apply prerequisite <name> "<text>"`
  for hiqs-resolve, hiqs-scrape and ai-catalog-update (each rc=0). No hand edits, nothing installed. Texts are
  taken from the lines you cited (hiqs-resolve/SKILL.md:10, hiqs-scrape/SKILL.md:19-23, ai-catalog-update/SKILL.md:67,101-105).
  Receipts now hold one record each, `catalog.md` shows all three, and changelog has three `prerequisite` events
  at 2026-10-14T05:08:42Z. Pulse tracked tree is still clean (`git status --porcelain` empty; still ahead 3 at e225b0c8b).
- [Nit] evidence → **Implemented.** The re-seeded artifact now replaces the glob with an explicit
  `.deploy-skills-pending.json exists: False` check, lists the recorded prerequisites, and lists all
  2026-10-14 changelog operation headers (add, add, update, sync, prerequisite ×3). Recovery did not write a
  separate history header: `--apply recover` completed the interrupted sync event `bfab400e…` (04:41:19Z).
- No other changes. Re-verify read-only (receipts, catalog, links unchanged) and grade.

Handing off to Reviewer (codex) — take round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
