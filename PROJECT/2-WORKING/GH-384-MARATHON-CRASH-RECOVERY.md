---
gh_issue: 384
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/384
title: "GH-384 — no recovery path after an interrupted marathon; a crash leaves a clean tree containing ungated commits and nothing reports it"
status: "2-WORKING — captured 2026-08-10 for release 0.3.0 Nightwatch. Issue #384 has NO `## Acceptance` section (verified 2026-08-10 via `gh issue view 384`) — criteria are authored in a separately-labelled section below, never inside `## Acceptance`, per this batch's drafting instructions. Awaiting preflight."
created: 2026-08-10
updated: 2026-08-10
owner: noel
doc_type: project
release: "0.3.0 Nightwatch"
complexity: 3
risk: 2
effort: 3
phases: 1
ratings_provisional: true
roadmap_exempt: false
related:
  - "#388 — the durable run log. Direction verified, not assumed: #384's tool reads `RELAY.md` (git-tracked and committed per-phase — confirmed via `git ls-files marathon-system/`) and `.tick/events/` (gitignored, `.gitignore:1`, but disk-persistent across an ordinary crash/reboot, per the issue's own observed 85-event table). #388 does NOT need to ship first — today's residue already carries the `phase.start`/`phase.approved` split this lane's detection depends on (verified `marathon_drive.py:1897` and `:1580`). #388 would make the ONE phase most likely to be silently lost — the interrupted phase's own turn transcript — durable, which deepens what this tool can show for that phase specifically, but does not block building the report-only tool now. So: #384 is not blocked on #388; #388 improves #384's depth for the single riskiest phase."
  - "#383 — the gate has no timeout, so an interruption can also be an indefinite stall rather than a crash. This lane's phase-state read applies unchanged to that shape, but nothing here adds a timeout signal."
  - "#382 — no memory telemetry, so this lane's tool can report THAT a phase never gated, never WHY the host died."
  - "#379 — the builder's own error detail is discarded to a temp file this lane does not touch; the tool can report a phase never reached the gate but cannot attribute a reason."
  - "#42 (CLOSED) — the stale-`relay-driver.lock` self-heal this lane's tool surfaces already ships (verified `marathon_drive.py:611-654`); it covers only the lock row of the issue's residue table, which is why the issue calls it insufficient on its own."
non_goals:
  - "Changing when the harness commits builder output (the issue's own suggestion 4). The issue itself frames this as 'a question rather than a recommendation' with 'good reasons for the current shape' — out of scope here."
  - "Editing `relay-automation/marathon.sh`, `utils/py/marathon_drive.py`, `relay-automation/relay-turn-lib.sh`, or `utils/py/rtl.py`. Those are the running driver / turn kernel per this repo's self-modification constraint — a marathon lane cannot edit the code gating its own run. This lane is scoped as a new, standalone, read-only script for that reason."
  - "Attributing WHY a phase or host died (panic cause, OOM). That is #382/#379's scope."
  - "Auto-reverting an ungated commit, or any other mutation. Report-only, in the spirit of `marathon-cleanup`."
goal: >
  An interrupted marathon (crash, OOM kill, closed laptop, Ctrl-C) leaves a working tree that
  `git status` reports as clean, while the branch can carry a builder commit whose phase never
  reached its gate. Nothing in the harness connects those two facts for an operator afterwards.
  Give the operator a report-only tool that reads the residue a crash already leaves (RELAY.md
  STATUS lines, tick events, the driver lock, git log) and prints the one fact that matters most:
  whether the last phase's commit was ever actually verified.
---

# GH-384 · a crash leaves a clean tree with ungated commits and nothing reports it

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10 as a lane of release 0.3.0 Nightwatch (named explicitly in `CHANGELOG.md:74`'s Nightwatch list, matching this issue's own wording verbatim). Issue has no `## Acceptance` section — criteria authored below in a separate section, scoped to avoid the two files this repo's self-modification constraint puts off-limits to a marathon lane. | Preflight, then fire as an independent lane — its write-set is a new script plus a doc addition, disjoint from every other Nightwatch lane touched so far. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/384

## The defect

Every row of the issue's residue table was checked against source rather than assumed:

| Residue (issue's claim) | Verified against |
|---|---|
| `.git/relay-driver.lock` present, holder pid dead | Real: `utils/py/rtl.py:477-499` resolves the lock path (normal clone / linked worktree / vendored copy); `utils/py/marathon_drive.py:611-654` is the GH-42 self-heal — it reads `pid`, probes `os.kill(pid, 0)`, and reclaims the lock only when the holder is confirmed dead (`:623-643`). |
| `.tick/events/` holds the phase history | Real, but **gitignored**: `.gitignore:1` is bare `.tick/`, confirmed with `git check-ignore -v .tick/events/foo.jsonl`. It survives an ordinary crash/reboot (disk-resident, not committed) — which is exactly what the issue's own table shows (85 events present after a kernel panic) — but is not durable against anything that also destroys local disk state. |
| `phases/<plan>--p*/` directories | **Stale as literally written.** GH-484 (merged same day as this capture, `9b49f3d`) flipped the default phase-output directory to `marathon-system/` — `utils/py/marathon_drive.py:697-700` and `relay-automation/marathon.sh:174-178` both compute that default now. `phases/` is still read as a fallback by the two existing read-only monitors (`relay-automation/marathon-ls.sh:110-125`, `relay-automation/marathon-detail.sh:39-50`), so an old run's residue there is still findable, but a *new* interruption lands in `marathon-system/<plan>--p*/`, not `phases/`. |
| A stale `ESCALATION.md` from an earlier failure | Consistent with code, not independently reproduced: `escalate()` writes `ESCALATION.md` (`marathon_drive.py:1185-1211`) but no removal call for that file exists anywhere in the `--retry` path (checked: no `os.remove`/`unlink` on `esc_file` in the file). A successful retry does not delete a prior escalation's file. |
| An ungated builder commit lands on the branch | **Structurally confirmed.** Every turn — builder's included — is committed by the turn kernel *immediately*, before review or gating: `relay-automation/relay-turn-lib.sh:1144` (`git -C "$RTL_ROOT" commit -q -m "relay(${task}): ${agent} turn ..." -- "${_commit_paths[@]}"`). The pre-advance gate runs later, inside `marathon_drive.py` (`run_pre_advance_gate()` called at `:1557`), and `marathon.phase.approved` is logged to `.tick/events` only **after** the gate passes (`:1580`). `marathon.phase.start` is logged once, at phase entry (`:1897`). So an interrupted phase can show, simultaneously: a `phase.start` event, no `phase.approved` event, `RELAY.md` still reading `STATUS: Open`, and a real commit already reachable from the branch tip. |
| Working tree clean | Follows directly from the row above — a committed change is not working-tree dirt. Not independently reproduced (would require an actual crash), but it is the necessary consequence of the commit-per-turn behavior just confirmed. |

**What already exists, and where it stops.** Two read-only monitors ship today: `relay-automation/marathon-ls.sh` (cross-repo LIVE/STALE/IDLE/GONE state from the driver lock, plus the newest tick event and newest `RELAY.md`) and `relay-automation/marathon-detail.sh` (per-repo `STATUS:`/`NEXT:` lines plus the last 10 tick events). Read in full: **neither cross-references a phase's `RELAY.md` status against its `.tick/events` history to flag a commit that landed without a matching `phase.approved` event.** That specific cross-reference — "this phase is Open/escalated AND a commit for it exists AND no gate ever passed" — is the one fact the issue calls "the single most important" and it is genuinely absent from both existing tools, not merely under-advertised. `relay-automation/marathon.sh`'s own argument parser (`:118-134`) has no `--status`/`--recover` flag at all — confirmed by reading the full `case` block: `--plan`, `--builder`, `--phases-dir`, `--target-root`, `--pre-advance-cmd`, `--dry-run`, `--force`, `--retry`, `--closeout-pr`, `--help`, nothing else.

**`marathon-cleanup` is exactly what the issue says it is.** Its `SKILL.md` (`~/.claude/skills/marathon-cleanup/SKILL.md`) is document-lifecycle reconciliation — archiving `VERIFIED-COMPLETE` task docs against PDDA/GitHub/CHANGELOG evidence — with no crash-recovery content anywhere in it. Confirmed by reading the whole file, not inferred from its description.

**No recovery procedure exists in any doc an operator would actually read.** `README.md`, `ROUTER.md`, `GUIDING-PRINCIPLES.md`, and `AGENTS.md` were grepped for "recovery", "interrupted marathon", "crash recovery", and "ungated commit" — the only hit is `README.md:109`, an unrelated beta-test branch note.

## Acceptance

*Issue #384, fetched 2026-08-10 via `gh issue view 384`, contains no `## Acceptance` section. Its actual headings are: TL;DR, "What an interrupted run leaves behind", "What recovery actually required", "Why this matters more than an ordinary gap", "Suggested", and "Related". There is no verbatim acceptance block to copy into this section — that would misrepresent the issue's own "Suggested" list (explicitly not phrased as criteria) as if it were one. Authored criteria are in the separate section immediately below instead, per this batch's drafting instructions for an issue with no acceptance criteria.*

## Acceptance — deviations from the issue

Not applicable in the usual sense — nothing was copied from an issue-side `## Acceptance` block, so there is nothing to declare a deviation *from*. See "Acceptance — authored" below for the full sourcing and scoping rationale, including the one explicit exclusion (the issue's suggestion 4).

## Acceptance — authored (the issue has none)

Sourced from the issue's "Suggested" list, items 1–3 (roughly its own value-for-effort order), scoped to what one marathon lane can build without touching this repo's self-modification-restricted files:

- [ ] A new, read-only report script (e.g. `relay-automation/marathon-recover.sh`, matching the style of the existing `marathon-ls.sh`/`marathon-detail.sh` — writes no state to the target repo, per the issue's own "report-only by default, in the spirit of `marathon-cleanup`") reads a repo's phase directories (`marathon-system/`, falling back to `phases/` — the same dual-read `marathon-ls.sh:117` and `marathon-detail.sh:44` already use for the GH-484 transition) and reports, per phase: its `RELAY.md` `STATUS:` line and whether a `marathon.phase.approved` tick event exists in `.tick/events/` for that phase's relay task.
- [ ] For any phase whose status is not terminal-approved (`STATUS: Open`, or an escalated state) and has no matching `phase.approved` event, the tool checks whether a commit naming that phase's relay task — the `relay(<task>): <agent> turn` pattern (`relay-turn-lib.sh:1144`) or the `marathon: phase <id> ...` patterns (`marathon_drive.py:1199`, `:1241`, `:1851`) — is reachable from the branch's current tip, and if so prints it **explicitly labeled as an unverified/ungated commit**. This is the fact the issue names as most important; it must be printed, not left for the operator to derive from separate reads of `RELAY.md` and `git log`.
- [ ] The tool also reports driver-lock state (present/stale/live), reusing the resolution already shipped in `relay-automation/driver-lock-lib.sh` / `marathon-ls.sh:83-106` rather than reimplementing pid-liveness logic.
- [ ] The tool's write-set does not include `relay-automation/marathon.sh`, `utils/py/marathon_drive.py`, `relay-automation/relay-turn-lib.sh`, or `utils/py/rtl.py`. Those four are the running driver / turn kernel this repo's self-modification rule puts off-limits to a marathon lane (a lane cannot edit the code gating its own run); a standalone script sidesteps this by construction. (`marathon-drive.sh:marathon_drive.py` is additionally one of the 12 GH-308 frozen twins — `test/gh308-frozen-twin-guard.sh:23` — a second, independent reason not to touch it here.)
- [ ] A short recovery procedure is documented in `README.md`: run the new tool after any suspected interruption; treat an "ungated commit" finding as unverified and re-run the gate (or revert) before trusting it; and note that a stale driver lock self-heals on the next run (GH-42, closed) but a lock reporting LIVE with a holder that looks dead should be checked, not assumed dead.
- [ ] A fixture demonstrates the tool actually distinguishes a gated phase from an ungated one — not merely that it runs without error. See Litmus tests below for the shape required.

## Litmus tests

- **Existence is not detection.** `marathon-detail.sh` already prints `STATUS:`/`NEXT:` lines and recent tick events for a repo — a script that does the same thing under a new name satisfies nothing here. The reviewer must confirm the new cross-reference specifically: `STATUS: Open` (or escalated) + no `phase.approved` event + a reachable phase commit → printed as ungated. A fixture with two phases, one Approved-with-`phase.approved`-event and one Open-with-a-landed-commit-and-no-event, must produce visibly different output for the two — same-output-for-both is a fail even if the tool "runs."
- **A green `validate.sh` proves nothing about this lane.** The suite does not exercise a fake-crash fixture unless this lane adds one; the reviewer must actually run the tool against the two-phase fixture above, not just check the gate went green.
- **Read-only means read-only.** Running the tool against a fixture repo must leave that repo's `git status` byte-identical before and after — no new commits, no new files, no lock touched. This is directly testable and should be checked, not assumed.

## Reversibility & blast radius

**Small.** Every artifact is new (a script, plus a documentation addition) — nothing existing is edited except a small addition to `README.md`, itself trivially revertible with one commit. The tool is read-only by requirement, so a defect in it cannot corrupt a monitored repo; the worst case is a wrong or missing report, not data loss.

**The self-modification constraint is why this lane is shaped the way it is, not a footnote.** The issue's own suggestion 1 literally proposes `marathon --status`/`--recover` — a subcommand on `relay-automation/marathon.sh` itself. That file is explicitly named as "the running driver" in this repo's self-modification rule: a lane whose write-set includes it cannot be a marathon lane, because the phase that would build it is gated by the very code it is changing. `utils/py/marathon_drive.py` carries the same restriction, and is additionally one of the 12 GH-308 frozen twins (`relay-automation/marathon-drive.sh:utils/py/marathon_drive.py`, `test/gh308-frozen-twin-guard.sh:23`) — editing its frozen Bash counterpart would separately require a `Frozen-twin-exception:` trailer. This doc's authored criteria deliberately route around both constraints by specifying a new, standalone script instead of a subcommand. If a future implementer instead adds `--status`/`--recover` directly to `marathon.sh` as the issue's prose literally suggests, that write-set must ship as a direct PR, not a marathon lane — say so plainly if that path is chosen.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "path_absent", "path": "relay-automation/marathon-recover.sh" },
    { "type": "grep_absent", "path": "README.md", "pattern": "ungated commit" }
  ],
  "artifacts":     [ "relay-automation/marathon-recover.sh", "README.md" ],
  "artifacts_new": [ "relay-automation/marathon-recover.sh" ],
  "remediation":   { "source": "issue #384", "criteria": "a report-only recovery tool flagging phase status, unverified/ungated commits, and driver-lock state after an interrupted marathon, plus a documented recovery procedure — ranking summary only, NOT the definition of done (that is the authored 'Acceptance — authored' block above; the issue itself has no ## Acceptance section)" },
  "lanes":         { "agy_safe": ["relay-automation/marathon-recover.sh", "README.md"], "orchestrator_only": [] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` reports the fix as still required while `relay-automation/marathon-recover.sh` does not exist; it flips once the script lands. `grep_absent` reports the fix as still required while `README.md` contains no occurrence of "ungated commit"; it flips once the recovery procedure is documented there. Verified 2026-08-10: neither the file nor the string exists anywhere in the current tree.

## Provenance

Filed as part of the 0.3.0 Nightwatch arc (`CHANGELOG.md:74`), alongside #383, #382, and #402 — the unattended-durability cluster. Captured 2026-08-10 from the issue text directly; every factual claim about current code was independently re-verified against `development` rather than trusted, per this batch's drafting instructions. `#388`'s own capture doc (`PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md`) already lists #384 in its `related` field — this doc's `related` entry above states the dependency direction explicitly in the other direction, since #388's phrasing ("much harder without") does not by itself establish which lane should ship first.
