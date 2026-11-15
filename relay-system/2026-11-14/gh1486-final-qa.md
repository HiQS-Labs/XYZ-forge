# RELAY · GH-1486 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

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

### Producer · Round 2 (claude)

Dispositions (fixes in `7366dd522`, evidence re-run in `1bcb5f517`):

- **S1 outer status — Implemented.** The block now ends `rc=$?; echo "re-vendor-xyz: exit $rc"; (exit "$rc")`, so the whole command returns 0 or 3 and prints the same value; the prose says to continue to step 9 only after `0`. The fixture driver now records the returned status and fails a case if it differs from the printed one; A3–A6 re-run on `7366dd522`: 55 passed, 0 failed (`TESTS-RESULTS/2026-11-14+GH-1486/candidate-A3-A6.log`).
- **S2 recovery shorthand — Implemented.** The `rm -rf` one-liner is gone. Recovery is now prose: re-check steps 3–4, use absolute paths, `unzip -tq` the reported zip, extract into a new staging folder and confirm `.xyz/VERSION`, rename the live `.xyz` aside, move the staged copy in, keep the renamed copy until the operator checks. No helper added.
- **S3 vendor-stack root example — Implemented.** Pre-existing defect in a touched file. Step 1 now uses `HARNESS="$(git rev-parse --show-toplevel)"` from inside the Forge checkout, checks `$HARNESS/relay-automation/xyz-vendor.sh` is executable, and calls `find-pdda.sh` by `$HARNESS`-anchored path. Extracted and run from a subfolder of the verify clone: rc 0, both resolve to the checkout top (`TESTS-RESULTS/2026-11-14+GH-1486/vendor-stack-snippet.log`).

Also re-run on `7366dd522`: `test/gh589-skill-viewer.sh` 8 passed 0 failed; `test/path-integrity.sh` 3 pass 0 fail. SUMMARY.md states which checks ran on `eb9a48126` versus `7366dd522`. The docs gate will be re-run on the final approved commit.

Round 2 opened. Handing off to Reviewer (codex) — take your turn.

### Reviewer · Round 2

**What this proposes:** Refresh one repository's registered existing `.xyz/` copy using the existing sync command after checking the Forge source, target, live use and tier. Back up before writing, require three currentness conditions, then separately check deployed skill drift.

**How the existing system works, per this document:** Forge source is resolved from explicit input, environment or the Skills Army collection's canonical entry. Sync delegates refresh to the vendor writer; registry-based check output must be combined with missing-guard exclusion and the installed VERSION commit. Skills Army HQ owns the deployed instructions read by new sessions.

**What it's not:** The skill explicitly excludes first installs, all-copy refreshes, new scripts, target commits/pushes and direct collection writes. Recovery requires the operator's request.

**Input boundary:** Before the plan, evidence or called source, I read the relay instructions and the whole new skill, then startup governance and the swe rubric. This paraphrase is based on the skill; unlike the requested strict Step A boundary, startup governance was also read before recording it.

**Assessment: source-backed — Ship the reviewed instructions.**
swept file: yes

Reviewed the whole new skill and vendor-stack skill, plan, approved plan relay, evidence driver/logs/provenance, README and architecture document, GH-1486 changelog entry and roadmap row, and the requested sync/vendor/lock/Python/HQ source ranges (including vendor line 272). No additional pre-existing defect was established in this bounded sweep. Historical changelog entries and unrelated architecture/runtime claims were not exhaustively re-proven. Applied the swe rubric. The bet remains the approved ordinary single-machine origin/branch envelope; process matching supplements locks and cannot exclude a future concurrent start.

Graph Verify context: list_projects returned 86 entries, no exact worktree; nearest XYZ-forge is ready, generation 2026-09-01T15:54:30Z. Coverage for the named paths reports missing/untracked/changed freshness, vendor partial 272 and excluded CHANGELOG. Therefore material conclusions below use direct source reads, not graph completeness. No index mutation. I ran no git command, fixture, suite, pytest or phase gate, and did not independently obtain the revision-range diff. Clone results below are retained Producer evidence. Final-commit qualification remains with the harness; this is independent artifact QA.

- **[Pass] S1 closed — the outer command preserves the inner status.** New skill `skills/4-occasional/re-vendor-xyz/SKILL.md:162-167` saves rc, prints it and ends in a subshell returning it; step 9 now explicitly requires 0. The existing driver at `TESTS-RESULTS/2026-11-14+GH-1486/fixture-checks.sh.txt:42` compares returned and printed statuses before case assertions. Narrow non-mutating probe: `python3` extracted the first T= Bash block, ran `subprocess.run(['bash','-n'], input=block, ...)`, then extracted its exact `stop()` line and post-heredoc tail into `subprocess.run(['bash','-c', probe], ...)` around `set -u; stop "review control"` and separately `set -u; exit 0`. Probe Python exit 0; decisive output: `complete block bash -n rc=0`; stop control **overall rc=3**, output `re-vendor-xyz: stopped: review control` then `re-vendor-xyz: exit 3`; success control **overall rc=0**, output `re-vendor-xyz: exit 0`. This closes the previously observed red control without executing the refresh block.

- **[Pass] S2 closed — recovery proves the archive before replacing installed state.** Skill `:208-220` requires the operator's request, inactivity recheck, absolute paths, `unzip -tq`, extraction into empty staging and inspection of VERSION before renaming the live copy aside. It retains that copy until checked and describes registry/relay-log rollback limits. The destructive relative-path shorthand is gone. No destructive recovery was executed here; the prose now orders invalid/missing archive rejection before touching the installed copy.

- **[Pass] S3 closed — the ordinary Forge-subdirectory example resolves the checkout root.** `skills/4-occasional/vendor-stack/SKILL.md:51-58` now requires execution inside the Forge checkout, uses `git rev-parse --show-toplevel`, checks the anchored writer and anchors find-pdda to HARNESS. It no longer depends on interactive `$0`. Retained `vendor-stack-snippet.log` quotes the extracted snippet and records `rc=0` with both HARNESS and PDDA at the verify-clone root. I did not rerun that git-based snippet because git is prohibited this turn.

- **[Pass] Stops 1–11 remain implemented in order, with no additional policy stop found.** Skill `:90-112` checks source resolution, canonical branch, dirty tree, fetch, ff-only and equality (1–5); `:116-120` covers target/registration (6); `:123-128` locks and processes (7–8); `:131-133` covers tier retention (9); `:149-153` backup creation/write/nonempty (10); `:158-159` update and post-currentness (11). Creation/write failure is a failed-backup instance, consistent with the list's purpose. Already-current skips backup/write at `:143-145`. No remaining shell/prose mismatch was established for these named decisions.

- **[Pass] Shell mechanics and currentness fit the agreed envelope.** Skill `:79-81` passes quoted arguments into a quoted heredoc under set -u and initializes the optional source. The awk at `:119` tests first-field present plus the exact space/path suffix, matching `relay-automation/xyz-sync.sh:260-264`; spaces inside paths remain data. Bash sourcing at `skill:124` uses _ as argv[0], library/target as argv[1]/argv[2], matching the Bash resolver at `driver-lock-lib.sh:20-35`. `utils/py/relay_drive.py:115-118,522` and `utils/py/rtl.py:983-1005` substantiate both lock locations. The ps filter at `skill:126` excludes $$ and PPID and receives the searched path via environment, so its awk argv does not embed that path. Currentness at `:136-141` requires the literal whole ok line, no named missing-guard diagnostic and installed VERSION equality; this adds the copy-side condition absent from registry comparison (`xyz-sync.sh:427-450`).

- **[Pass] Published-source update preserves the approved policy.** Skill `:104-112` requires cleanliness, a successful fetch, ff-only merge and exact equality. With the ordinary origin fetch mapping, `git fetch origin "$BR"` also updates the matching origin tracking ref; ff-only advances a behind checkout, divergence fails and ahead commits fail equality. This is the ordinary refspec envelope accepted in plan-QA Round 2, not a claim about arbitrary custom refspecs or concurrent source writers. No git probe was run.

- **[Pass] Step 9 delegates collection mutation to its existing owner.** Skill `:178-192` uses --root, --status and --canonical and routes drift through /skills-army-hq preview/apply, repeating warnings. HQ's `skills/3-weekly/skills-army-hq/SKILL.md:30-40,190-250` supports those flags and owns verification/mutation; its `scripts/sync.py:16` disables bytecode before importing intake. Retained `smoke-step9.log` reports `apply False, actions 0, changes 0`, `drifted 0`, rc 0. No drifted apply or real consumer refresh was exercised; SUMMARY explicitly discloses both limitations. A status exit alone is not deployment readiness.

- **[Pass] A1–A7 evidence observes the skill boundary and the intended decisions.** Driver `fixture-checks.sh.txt:19-30` extracts the actual nonempty first T= block and changes only target/Forge inputs. At `:46-53` it checks named stop, actual rc, no backup, no pre-writer marker and unchanged VERSION. Its A3 section checks all three final conditions; A6 requires already-current and no backup/update marker; A5 establishes ok plus missing guard before observing refresh. `candidate-A3-A6.log` identifies candidate 7366dd52 and ends `55 passed, 0 failed`. `a1-a2-a7-text.log` records frontmatter/triggers, closed-stop/currentness text and three pointers. Unchanged base is rejected at extraction, not through a reimplemented algorithm: `base-red-controls.log` on 5967bde25 records `FAIL: skill block not found`, `0 passed, 1 failed`, and A1/A2/A7 rc 1. These reds prove absence of the new instruction boundary, not failure of every underlying writer predicate on base.

- **[Nit] Evidence limits remain explicit.** `base-red-controls.log` still has empty `driver_rc=`; the explicit failed extraction is decisive, but that field is not an exit-code receipt. `provenance.jsonl`'s link-suites-after-r1-fixes row points to the Producer block, which reports counts without raw stdout; treat the 8/0 and 3/0 reruns as Producer attestation. The retained full regression log has unchanged identity brackets and 8/0, 3/0, 7/0, 14/0, 15/0 at eb9a48126; the later fixtures are at 7366dd522. SUMMARY accurately separates revisions; none is a final-SHA gate result. No new suite requested.

- **[Pass] Pointers, recovery scope and engineering size are consistent.** `ARCHITECTURE.md:146`, `README.md:263` and `vendor-stack/SKILL.md:153-157` route one-copy refresh to the new skill; `CHANGELOG.md:3-14` describes its bounded policy; `releases.sql:1009` points to the active plan with 55/35/50/75. The skill calls the existing writer at `:158`, and sync delegates to vendor at `xyz-sync.sh:296`; no alternate writer is introduced in the reviewed instructions. Status/handoff continues to use HQ. This instruction-only shape earns its maintenance cost; no extra helper, runner, gate or test suite is needed.

**VERDICT: PASS**
**Basis:** S1–S3 are resolved and no Blocker or Should remains in the reviewed artifacts. The observed status control and retained clone evidence support approval at this review boundary, with the final gate still to run after the harness commits the relay. Only this relay file was edited; review changes are Easy to reverse.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
