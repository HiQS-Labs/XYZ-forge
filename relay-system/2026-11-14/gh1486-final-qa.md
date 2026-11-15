# RELAY · GH-1486 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1486-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the completed change on this branch against base `5967bde25`: `git diff 5967bde25..dc31da6af`. Files: `skills/4-occasional/re-vendor-xyz/SKILL.md` (new), `ARCHITECTURE.md`, `README.md`, `skills/4-occasional/vendor-stack/SKILL.md`, `CHANGELOG.md`, the plan `PROJECT/2-WORKING/GH-1486-RE-VENDOR-XYZ-SKILL.md`, evidence under `TESTS-RESULTS/2026-11-14+GH-1486/SUMMARY.md` (start there; driver `TESTS-RESULTS/2026-11-14+GH-1486/fixture-checks.sh.txt`), the approved plan thread `relay-system/2026-11-14/gh1486-plan-qa.md`, and the ledger row for GH-1486 in `releases.sql`.
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-14
- Operational envelope: an instruction-only skill an agent follows on one developer's machine to refresh one repository's `.xyz/` copy by sequencing existing commands (`relay-automation/xyz-sync.sh`, `xyz-vendor.sh`, Skills Army HQ `sync.py`). No script, flag or suite is added (`AGENTS.md` *No new tests*, GH-831); a new `test/` file or `validate.sh` entry would be a finding. The operator chose a separate skill over a `vendor-stack` section (issue #1486, first comment); do not reopen that.
- Definition of Done: each plan acceptance item A1–A7 is satisfied by evidence that would fail on base; the skill's shell block does what its prose and closed stop list say; no duplicate writer or helper slipped in; the evidence substantiates the claims.

### Step A: paraphrase first (GH-1414). Do this BEFORE reading anything else.
Read ONLY `skills/4-occasional/re-vendor-xyz/SKILL.md`. Do not open the plan, evidence or source yet. Then, at the top of your review block, write:
- **What this proposes** (2–5 sentences)
- **How the existing system works, per this document** (2–5 sentences)
- **What it's not** (short; ground exclusions in the skill's text and label any inference)
- **Input boundary:** what you had read when you wrote the paraphrase.

### Step B: source-backed validation
Now read the plan, the evidence, the diff and the source it calls (`relay-automation/xyz-sync.sh`, `relay-automation/xyz-vendor.sh:36-75,230-240,420-516`, `relay-automation/driver-lock-lib.sh`, `utils/py/relay_drive.py:110-125,515-525`, `utils/py/rtl.py:980-1010`, `skills/3-weekly/skills-army-hq/SKILL.md:20-90,190-250`). Label this assessment **source-backed**. Answer with `file:line` evidence:

1. Does the steps 1–8 block implement each of the 11 listed stops, in the stated order, and nothing that stops outside the list? Name any stop whose shell check differs from its prose.
2. Shell correctness under `set -u` in `bash -s` with a quoted heredoc: quoting of paths with spaces, the `awk` registry match (exact `present` row for `$T/.xyz`), the subshell that sources `driver-lock-lib.sh`, the `ps` filter (does it exclude itself and its parent, and can it match its own argv?), the `current()` function's three conditions, and the exit codes (0 current, 3 stop) as seen by the outer `echo "re-vendor-xyz: exit $?"`.
3. Step 2 runs `git fetch origin "$BR"` then `git merge --ff-only origin/$BR`. Is the remote-tracking ref reliably updated by that fetch form, and is the ff-only merge safe on the operator's Forge checkout (clean tree already required)?
4. Step 9: is the read-only status block correct (`--root`, `--status`, `--canonical`), and does the prose keep writes with `/skills-army-hq`?
5. Evidence: does the fixture driver run the skill's own extracted block (not a reimplementation), and do A3–A6 assertions observe the right things (named stop, no backup, no `update` call, `VERSION` unchanged; three-part current test; "already current" with no writer call; `ok`+guard-missing not accepted)? Does each base red control really fail on `5967bde25`? Is anything claimed that the logs do not show?
6. Pointers and docs: are `ARCHITECTURE.md`, `README.md`, `vendor-stack` and `CHANGELOG.md` accurate and consistent with the skill? Are the recovery instructions safe?
7. What prevents an unchanged base from being reported as delivered, and where is that rejection observed?
8. Over- or under-engineering against the envelope. Do not ask for new suites.

Write graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), then a VERDICT. Set STATUS to Approved only if no `[Blocker]` or `[Should]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

**What this proposes:** Refresh one registered repository's existing `.xyz/` copy through a single shell block that checks published Forge source, live-run exclusion and tier preservation before backing up and invoking the existing writer. It verifies the resulting copy using check output, missing-guard exclusion and the copy's recorded source commit, then reports deployed-skill drift separately.

**How the existing system works, per this document:** `xyz-sync.sh` dispatches to `xyz-vendor.sh`, and the registry participates in `check`, so an `ok` line alone does not establish the copy's contents. Driver locks and process arguments indicate live use, while Skills Army HQ owns the separate collection from which agent sessions load skill instructions.

**What it's not:** The text excludes first installs, all-copy refreshes, new scripts, direct collection writes and target commits/pushes. It leaves recovery operator-requested and warns that restoring the copy also rolls back its relay threads and tick logs.

**Input boundary:** At paraphrase time I had read only this relay's instructions and `skills/4-occasional/re-vendor-xyz/SKILL.md`; no plan, evidence or called source.

**Assessment: source-backed — Block pending bounded instruction corrections.**
swept file: yes

Read the entire new skill and touched `vendor-stack` skill, the plan and approved plan relay, evidence summary/driver/logs/provenance, README and architecture document, GH-1486 changelog entry and ledger row, and the requested writer/lock/HQ source. Historical CHANGELOG entries were not exhaustively re-audited. Pre-existing defects in the touched instructions were considered: S3 below is one. No git commands, suites, pytest, executable fixtures or phase gates were run. Consequently I did not independently inspect the Git revision-range diff or replay the retained clone results; those remain recorded Producer evidence, not a fresh gate on the final SHA.

Graph context (Verify, source fallback): `list_projects` returned all 86 projects and no exact task worktree. Nearest `XYZ-forge` was ready; coverage generation `2026-09-01T15:54:30Z` reported missing/untracked/changed metadata for the relevant paths, vendor partial range 272, and excluded CHANGELOG. Material claims use direct reads of this worktree, including vendor 272; no stale graph result establishes completeness.

- **[Should] S1 — Preserve the stop status through the outer shell block.** `skills/4-occasional/re-vendor-xyz/SKILL.md:82` exits the inner Bash with 3, but `:162` ends the complete copy-paste command with a successful `echo`. This contradicts “the block exits `3`” in the stop contract and makes “After exit `0`” at `:173` ambiguous for an agent observing the shell tool's status. Save the inner status, print it and return that status from the complete shell call, or explicitly define the contract as a printed inner result and require that result for step 9. Prefer real status propagation. Update the existing manual driver to observe the shell return status as well as the printed value; no new suite.
  Observed input: any inner `stop`, reproduced using the exact extracted `stop()` definition and outer echo with only `stop "review control"` between them. Command (run via Python `subprocess.run(['bash','-c', probe], capture_output=True, text=True)`, Python exit 0):
  ```bash
  bash -s <<'RE_VENDOR_XYZ'
  stop() { printf 're-vendor-xyz: stopped: %s\n' "$*"; exit 3; }
  stop "review control"
  RE_VENDOR_XYZ
  echo "re-vendor-xyz: exit $?"
  ```
  Decisive output: `re-vendor-xyz: stopped: review control`, then `re-vendor-xyz: exit 3`; **overall subprocess exit status: 0**. This was a non-mutating shell-semantics probe, not the refresh block or a fixture run.
  Affected scope: the outer steps 1–8 status/reporting boundary for every listed stop; the inner checks themselves do stop before the writer.
  Falsifier: the corrected complete command returns 3 for this control and 0 for an inner successful exit, while preserving the displayed result. If retaining printed-only semantics instead, prose must unambiguously forbid treating the shell tool's rc 0 as permission for step 9.

- **[Should] S2 — Replace the unsafe recovery shorthand.** `skills/4-occasional/re-vendor-xyz/SKILL.md:206-209` recommends `cd <target> && rm -rf .xyz && unzip -q <zip>`. This deletes the only live copy before checking that the ZIP can be read/extracted, leaves paths unquoted, and instructs recursive cleanup against a relative, unproven target contrary to AGENTS.md's dangerous-command rule. Operator-requested recovery does not validate those operands. Remove this runnable shorthand; describe resolving and verifying the absolute target and archive, extracting/inspecting into a separate staging directory first, then replacing only the proven `.xyz` path while retaining recovery state. No helper or new recovery subsystem is needed.
  Observed input: the literal command at `:207`, with a valid target and an absent/unreadable `<zip>`: deletion is ordered before unzip can reject the archive. This is a source-order finding; I did not execute the destructive command.
  Affected scope: operator-requested backup recovery only; normal refresh and the stop list need no expansion.
  Falsifier: recovery with an absent or corrupt ZIP leaves the installed copy intact, and a target containing spaces resolves as one validated absolute path. A recovery recipe that establishes both properties before replacement closes this finding.

- **[Should] S3 — Correct the pre-existing Forge-root example in the touched vendor-stack file.** `skills/4-occasional/vendor-stack/SKILL.md:51-56` calls `skills/4-occasional/vendor-stack/../..` the harness root, and uses `dirname "$0"` in a Markdown shell snippet. That traversal resolves to `skills/`, and `$0` in an interactive/copy-paste shell is not the skill's filename. Step 2 then calls a nonexistent `$HARNESS/relay-automation/xyz-vendor.sh` (`:66`). Replace the misleading example with the already-mentioned root lookup from an identified Forge checkout, and validate the writer exists. A three-level traversal alone does not fix the `$0` problem.
  Observed input: exact documented directory `skills/4-occasional/vendor-stack/../..`. Non-mutating command `python3` with `p=Path('skills/4-occasional/vendor-stack/../..').resolve(); print(p.relative_to(Path.cwd())); print((p/'relay-automation/xyz-vendor.sh').is_file())` exited 0 and printed `skills` and `False`.
  Affected scope: vendor-stack's source-resolution instructions, which the new skill directs first-install users to; no installer implementation change.
  Falsifier: follow the corrected instructions from a Forge checkout whose path contains spaces; `$HARNESS/relay-automation/xyz-vendor.sh` must resolve to the existing writer. An ordinary copy-paste shell must not depend on `$0` naming the Markdown file.

- **[Pass] Stops and ordering otherwise match the bounded policy.** New skill `:90-112` covers source stops 1–5; `:116-120` covers target stop 6; `:123-128` covers lock/process stops 7–8; `:131-133` covers tier stop 9; `:149-153` covers backup stop 10 (including inability to create/write it); `:158-159` covers update/current stop 11. Already-current skips only backup/write (`:143-145`). Failures to make/write the backup are reasonably instances of the backup stop, not extra policy stops. S1 concerns the outer return contract. No requirement for a new lock protocol or stronger process identity is implied.

- **[Pass] Quoting, registry match, lock subshell and currentness fit the stated ordinary-path envelope.** Skill `:79-81` uses a quoted heredoc with explicit arguments and initializes optional Forge under `set -u`; data paths are quoted. At `:119` the awk checks the `present` first field and exact space-plus-path suffix, so spaces inside the path do not split the comparison; sync prints that suffix at `relay-automation/xyz-sync.sh:260-264`. At `:124` Bash is intentional because the sourced library uses Bash syntax; `_` supplies `$0`, leaving library and target in `$1/$2`. Library `:20-35` resolves ordinary and linked-worktree locks. Python drivers derive their harness root (`utils/py/relay_drive.py:115-118`) and lock it (`:522`), with vendored fallback in `utils/py/rtl.py:983-1005`; both required lock locations are checked. The `ps` awk (`skill:126`) excludes `$$` and `$PPID`; the sought path is supplied through environment, not interpolated into awk argv, so the awk text does not match itself. This remains a supplementary argv check, not atomic exclusion against future starts. `current()` (`:136-141`) checks the whole literal `ok` line, excludes the guard diagnostic and compares installed VERSION. These correspond to registry comparison and installed-guard behavior at `xyz-sync.sh:427-450`.

- **[Pass] Source update is appropriate for an ordinary origin refspec, with an explicit limit.** Skill `:104-112` requires a clean tree, successful fetch, ff-only merge and equality. With the usual `remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*`, explicit `fetch origin "$BR"` also updates the matching remote-tracking ref; ff-only advances a behind checkout without rewriting local commits, while divergence fails and ahead history fails final equality. This is not proof for arbitrary custom remote refspecs or concurrent checkout writers, and no git probe was run here. The approved plan's Round 2 Q2 expressly accepts this ordinary origin/branch envelope and the deliberate fast-forward.

- **[Pass] Step 9 keeps deployed writes with the existing owner.** Skill `:176-190` passes `--root`, `--status`, `--canonical` and delegates drift to `/skills-army-hq`; that owner's `SKILL.md:30-40,190-250` supports these flags and owns preview/apply and source verification. Its `scripts/sync.py:16` sets `sys.dont_write_bytecode = True` before importing intake, addressing the local bytecode-write concern. Retained `smoke-step9.log` reports `apply False, actions 0, changes 0`, `drifted 0`, rc 0; no actual drifted-skill apply was exercised, as SUMMARY explicitly discloses. Step 9 is conditional on the genuine success result clarified in S1.

- **[Pass] Retained A3–A6 evidence measures the intended decisions, with S1's status limitation.** `TESTS-RESULTS/2026-11-14+GH-1486/fixture-checks.sh.txt` extracts the first `T=` Bash block and changes only the target/Forge inputs; it does not reimplement the algorithm. `stop_case()` checks a named stop, unchanged VERSION hash, backup count and absence of the immediate pre-writer marker. `run_skill()` currently parses printed rc, explaining why S1 is not detected. A3 checks drift before and all three current conditions after; A6 observes “already current” and no backup/update marker; A5 first establishes `ok` plus missing guard, then observes a refresh instead of accepting currentness. `candidate-A3-A6.log` records the eight stops and `55 passed, 0 failed`; regression logs record 8/0, 3/0, 7/0, 14/0, 15/0 with matching identity brackets. These are retained clone results at `eb9a48126`, not reruns here or final-SHA qualification.

- **[Pass] Base rejection is observed at the new skill boundary.** `base-red-controls.log` records `FAIL: skill block not found` and `0 passed, 1 failed` on `5967bde25`; A1 glob fails and A2/A7 text lookups return rc 1. Thus unchanged base cannot pass by exercising only the pre-existing writer. These reds show absence of the new instructions, not that every underlying happy-path predicate fails on base. **[Nit]** That log's `driver_rc=` is empty: retain the actual exit code when next collecting evidence; the explicit failed extraction is still decisive.

- **[Pass] Pointers and scope are coherent apart from S3.** `ARCHITECTURE.md:146`, `README.md:263`, vendor-stack `:151-155` point to the new skill with consistent one-copy semantics. `CHANGELOG.md:3-14` accurately describes the intended stop/currentness policy; `releases.sql:1009` links the active plan with the stated 55/35/50/75 rating. The skill delegates the update at `:158`, adds no alternate copy writer, and leaves collection mutation at `:186-190` with HQ. This is proportionate to the instruction-only envelope; fixes require text/shell-status corrections and existing manual evidence, not a new suite, helper, gate or runner. No further pre-existing defect was established in the bounded source sweep; unrelated historical architecture/changelog claims were not re-proven against runtime.

**VERDICT: FAIL**
**Basis:** S1–S3 remain required corrections: truthful outer status, safe recovery instructions and the pre-existing broken source-root example in a touched skill. Most A1–A7 evidence is well targeted, but it does not close those findings or constitute a new final-commit gate. Review-only changes are Easy to reverse and confined to this relay; no artifact/source edits were made.

Handing off to Producer (claude) — disposition S1–S3, make the bounded corrections and update relevant existing manual evidence, then open Round 2; go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
