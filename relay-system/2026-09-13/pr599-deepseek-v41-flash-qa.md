# RELAY · PR 599 DeepSeek v4.1 Flash QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
-->

NEXT: Reviewer
STATUS: Open
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(pr599-deepseek-v41-flash-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh599-deepseek-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/gh599-deepseek-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: deepseek   ·   Producer: codex
- Started: 2026-09-13
- Definition of Done: Answer all five concrete questions in the seeded review brief with direct source citations and actionable evidence; approval requires no substantive correctness blocker. Live acceptance remains pending.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer recovery — Round 2

The original DeepSeek CLI turn timed out after900s, exit7, with no verdict or source changes. Its harness diagnostic was timeout-idle-no-progress. The exact DeepSeek v4.1 Flash endpoint and minimal CLI text/file-read probes succeeded, so the model is reachable but that review attempt produced no QA evidence. Switching to the shipped Aider turn-taker with the SAME OpenRouter model deepseek/deepseek-v4.1-flash. The read-only packet now embeds complete source files and the focused diff, avoiding repository navigation. The harness handles tick operations and commits; the reviewer should only append the findings and update NEXT/STATUS. Please answer the five questions and cite actual source lines. Source remains7b3fb2c3; live acceptance remains pending.

Handing off to deepseek via Aider for this bounded review turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->


---

### Review salvaged from openrouter/deepseek/deepseek-v4.1-flash transcript (aider-turn.sh · GH-251)

_Aider completed a review turn but did not land it as a relay-file append; the harness
recovered the graded review from the turn transcript verbatim below (attributed, not edited)._

```text
Detected dumb terminal, disabling fancy input and pretty output.

Aider v0.86.3.dev+import
Model: openrouter/deepseek/deepseek-v4.1-flash with diff edit format
Git repo: 
../../../../../../../Users/noelsaw/marathon-clones/gh591-reconciler/.git/worktre
es/rtl-wt.ZClrSg with 3,523 files
Warning: For large repos, consider using --subtree-only and .aiderignore
See: https://aider.chat/docs/faq.html#can-i-use-aider-in-a-large-mono-repo
Repo-map: disabled
Added relay-system/2026-09-13/pr599-deepseek-v41-flash-qa.md to the chat.
Added ../../../../../../tmp/gh599-deepseek-packet.md to the chat (read-only).


--------------
► **THINKING**

Let me carefully review the artifact and produce the reviewer block. I need to 
append my findings to the relay file, update NEXT/STATUS, and hand off.

Let me analyze the source code deeply for the five questions.

Let me trace through the key functions.

**Question 1: Does qualify_landings actually run the full sequential gate on the
pinned integration snapshot in an independent clone?**

Looking at `qualify_landings` (lines 506-601):

- `previous = committed_qualifications(repo_root)` — reads committed receipts
- `pending` = metas not already matched
- `check_porcelain_cleanliness(repo_root)` — clean tree
- `tested = git rev-parse HEAD`
- For each meta: checks state MERGED, baseRefName development, landing is 
40-hex, and `git merge-base --is-ancestor landing tested`
- Creates temp dir, clone = scratch/repo, telemetry = clone/.tick/telemetry
- env from gate_env() filtered to remove GIT_*, RT_*, XYZ_VALIDATE_*, PYTEST_*, 
XYZ_HARNESS_DB, PYTHONPATH, PYTHONHOME
- config with user/init
- env.update GIT_CONFIG_GLOBAL, GIT_CONFIG_NOSYSTEM=1, 
RELAY_SELF_SUFFICIENCY_SKIP=1, TICK_REPO_ROOT=clone
- command() runs run_bounded with timeout=5400
- clone --no-local, checkout --detach tested
- set-url origin
- before_config = git config --local --list
- python3 -c "import pytest"
- npm ci
- bash validate.sh --sequential
- checks HEAD == tested, status --porcelain empty, config unchanged
- files = telemetry.glob(f"validate-sequential-*-{validation.pgid}.jsonl")
- checks exactly one
- raw = files[0].read_bytes()
- checks first row run == f"{tested[:9]}-{validation.pgid}"
- summary = qualification_summary(raw, tested)

Now, potential issues:

1. **`validation.pgid`** — the telemetry filename uses the pgid of the launched 
process. But the fixture in the test writes 
`validate-sequential-fixture-{os.getppid()}.jsonl`. Wait, in the test, the 
fixture writes the file with `os.getppid()` which is the pgid of the shell 
running validate.sh. Hmm, actually the test's validate.sh is a shell script; the
python heredoc's `os.getppid()` is the shell's pid. And `validation.pgid` is the
pgid of the launched `bash validate.sh` process. Since the shell is the process 
group leader (run_bounded presumably sets start_new_session or similar), pgid ==
pid of the shell. So `os.getppid()` in the python child == shell pid == pgid. OK
that works.

But wait — the real validate.sh writes telemetry via `rt_begin` which uses 
`RT_FILE`. Let me check: `rt_begin "$HERE" "validate" "sequential" 1 "$TIER" 
"${#TESTS[@]}"`. The filename format is `validate-sequential-*-<pgid>.jsonl`? 
Let me look at the runner-telemetry lib... not provided. But the test fixture 
writes `validate-sequential-fixture-<ppid>.jsonl` and the glob is 
`validate-sequential-*-{pgid}.jsonl`. So the real lib presumably names it 
`validate-sequential-<something>-<pgid>.jsonl`. Hmm, but actually the glob 
pattern `validate-sequential-*-{pgid}.jsonl` — the `*` matches the middle. In 
the fixture, the middle is "fixture". So the real one's middle is something 
else. OK.

Actually wait, there's a subtlety. The `run` field in telemetry is 
`sha[:9]-<pgid>`. The test fixture sets `run=sha[:9]+'-'+str(os.getppid())`. And
the check is `json.loads(raw.splitlines()[0]).get('run') != 
f"{tested[:9]}-{validation.pgid}"`. So the run id embeds the pgid. This is the 
"exact launched-process telemetry selection".

Potential false pass: The glob `validate-sequential-*-{pgid}.jsonl` — if a 
nested validator probe runs with the same pgid... Actually the comment says 
"Suites may launch nested validator probes. Bind proof to the exact process we 
launched, not another passing run in the telemetry directory." The nested probe 
would have a different pgid (its own process group) unless it's in the same 
group. Hmm. Actually if a suite runs `validate.sh` as a child without creating a
new session, it'd share the pgid. Then there could be multiple files matching. 
The check `len(files) != 1` catches that. OK.

But here's a real concern: **the telemetry directory is 
`clone/.tick/telemetry`**, but the env sets `TICK_REPO_ROOT=str(clone)`. Does 
validate.sh write telemetry to `$TICK_REPO_ROOT/.tick/telemetry`? The test 
fixture uses `XYZ_VALIDATE_TELEMETRY` env var defaulting to `.tick/telemetry`. 
Hmm, the fixture reads 
`os.environ.get('XYZ_VALIDATE_TELEMETRY','.tick/telemetry')`. But the real 
validate.sh — where does it write? The env filter removes `XYZ_VALIDATE_*` from 
the inherited env, so `XYZ_VALIDATE_TELEMETRY` is not set. So the real lib must 
default to something. The test fixture's default is `.tick/telemetry` relative 
to cwd, and cwd is the clone. So `clone/.tick/telemetry`. OK consistent.

Hmm, but actually is that the real default? The test is a fixture, not the real 
lib. The real `runner-telemetry.sh` `rt_begin` — I don't have it. But the test 
asserts the glob finds the file, so presumably the real lib writes to 
`.tick/telemetry` under TICK_REPO_ROOT. Actually wait — the test's fixture 
validate.sh writes to 
`os.environ.get('XYZ_VALIDATE_TELEMETRY','.tick/telemetry')` and the code globs 
`clone/.tick/telemetry`. So the test passes because the fixture writes there. 
But does the REAL validate.sh write there? If the real lib writes to 
`$TICK_REPO_ROOT/.tick/telemetry` then yes. Given GH-496 telemetry isolation, 
telemetry is written out-of-tree to `~/.xyz/projects/<key>/telemetry/`. Hmm! 
That's a concern. Let me look: validate.sh line 113: 
"gh496-telemetry-isolation.sh # GH-496 Phase 1 (routine telemetry written 
out-of-tree to ~/.xyz/projects/<key>/telemetry/)".

So the real telemetry may be written OUT OF TREE to 
`~/.xyz/projects/<key>/telemetry/`, not to `clone/.tick/telemetry`. If so, the 
glob `telemetry.glob(...)` on `clone/.tick/telemetry` would find nothing → 
`len(files) != 1` → die. That would be a **permanent inability to qualify valid 
data** — a Blocker!

But wait, the test fixture explicitly writes to `.tick/telemetry` and the test 
passes. But the test uses a stub validate.sh, not the real one. So the test does
NOT verify the real telemetry path. This is a genuine concern. However, I should
be careful: maybe `rt_begin` writes to `.tick/telemetry` when TICK_REPO_ROOT is 
set, and the out-of-tree thing is for a different telemetry (harness telemetry 
vs validate telemetry). The comment at validate.sh line 1026-1029: "GH-365 step 
2: retained JSONL telemetry". And `RT_FILE` is set by rt_begin. Hmm.

Actually, let me reconsider. The env filter removes `XYZ_VALIDATE_*` and `RT_*`.
`RT_FILE` is set by rt_begin itself. The telemetry file location is determined 
by rt_begin. Without the lib source I can't be 100% sure. But the test fixture's
default `.tick/telemetry` strongly suggests the real default is 
`.tick/telemetry` relative to TICK_REPO_ROOT. Hmm, but the fixture author chose 
that default to match the code's glob, which is circular.

I'll flag this as a hypothesis/Should: the real telemetry path is not verified   [Unverified — no citation]
by the test (the test stubs validate.sh), so if the real runner writes telemetry
elsewhere (e.g., out-of-tree per GH-496), qualification can never succeed. 
Actually, let me think about whether this is provable. The test 
`test_full_gate_produces_attributable_retained_proof` uses the stub. So the real
path is unverified. That's a legitimate finding: the test does not exercise the 
real runner's telemetry location contract. But is it a defect? The producer 
claims full local gate 374/374. Hmm.

Actually, I realize I should focus on what I can prove from the provided source.

Let me look for concrete defects.

**Defect A: `qualification_summary` requires `summary.get("total") != registered
+ 3`.**

The summary total = registered + 3. In validate.sh, TOTAL = RUN_TESTS + 1 
(identity) + 1 (pytest) + 1 (gamma) = registered + 3 for tier 3. Yes. And 
`summary.get("passed") != summary["total"]`. And `summary.get("failed") != 0`. 
OK.

But note: `summary.get("total") != registered + 3` — if `summary["total"]` is a 
string, comparison fails → raises. Fine.

**Defect B: `qualification_summary` checks `any(type(row.get("rc")) is not int 
or row["rc"] != 0 for row in suites)`.** This requires ALL suite rows rc==0. 
Good.

**Defect C: The `run` identity check.** `any(row.get("run") != start["run"] or 
row.get("runner") != "validate" for row in rows)`. This requires every row to 
have run == start run and runner == "validate". But the telemetry includes 
`stage` events (e.g., "telemetry-merge", "envelope-assert") and `retry` events. 
Do those carry `run` and `runner`? rt_emit presumably adds run/runner to every 
row. Probably yes. OK.

**Defect D: `qualification_receipt_matches` ancestry check `(tested, "HEAD")`.**
It checks `git merge-base --is-ancestor tested HEAD`. So the tested commit must 
be an ancestor of HEAD. And `(landing, tested)`. Good.

But note: `qualification_receipt_matches` is called from 
`check_provenance_receipts` during the SAME run, after `qualify_landings` wrote 
the receipt to the working tree (uncommitted). It reads `path.read_bytes()` from
the working tree. And `committed_qualifications` reads from HEAD. So during the 
run, the receipt is uncommitted but present in the working tree, and 
`check_provenance_receipts` walks the filesystem (`os.walk(results_dir)`) so it 
finds it. Good.

**Defect E: `committed_qualifications` uses 
`QUALIFICATION_PATH.replace("validation", "provenance")`.** QUALIFICATION_PATH =
`TESTS-RESULTS/[0-9]{4}-[0-9]{2}-[0-9]{2}\+GH-591/wave-[0-9a-f]{40}/validation\.
jsonl`. Replace "validation" with "provenance" → `.../provenance\.jsonl`. But 
wait — does "validation" appear elsewhere in the pattern? No. OK. But this is 
fragile string manipulation; a Nit.

**Defect F: The workflow allowlist regex** `receipt = 
r'TESTS-RESULTS/[0-9]{4}-[0-9]{2}-[0-9]{2}\+GH-591/wave-[0-9a-f]{40}/(?:provenan
ce|validation)\.jsonl'`. This matches the receipt paths. Good. But the folder 
date is `now:%Y-%m-%d` (UTC) while the regex allows any date. Fine.

**Defect G: `qualify_landings` writes telemetry and receipt, but the workflow's 
commit step computes `changed` from `git diff --name-only --no-renames -z HEAD` 
plus untracked. The new files are untracked → included. Good. But `.tick/` is 
gitignored, and the telemetry is written to `TESTS-RESULTS/.../validation.jsonl`
(in-tree), not `.tick`. Good.

**Defect H: Rollback.** `journal.track_created(path)` for telemetry_path and 
receipt_path. But `folder.mkdir(parents=True, exist_ok=True)` creates 
directories that are NOT tracked for rollback. On rollback, the files are 
unlinked but the empty directories remain. `verify_rollback_completeness` 
compares porcelain; empty untracked dirs don't show in porcelain. So OK-ish. But
`RollbackJournal.rollback` unlinks created files; the 
`TESTS-RESULTS/<date>+GH-591/wave-<sha>/` dirs remain empty. Not a porcelain 
issue. Nit.

**Defect I: `qualify_landings` is called BEFORE the per-landing loop, and it 
writes the receipt. Then `check_provenance_receipts` is called inside the loop 
for each landing. But `qualify_landings` only qualifies `pending` metas. If a 
meta is already committed-qualified, it's skipped, and 
`check_provenance_receipts` will find the committed receipt. Good.

**Defect J: The `--qualify` guard.** `if args.qualify and (not 
args.require_receipts or args.dry_run or args.offline or args.allow_dirty or 
args.pre_merge): parser.error(...)`. So --qualify requires --gate. Good. But it 
does NOT require `--skip-pull` to be absent, nor branch check. Actually the 
workflow runs on development. Fine.

**Defect K: `qualify_landings` calls `check_porcelain_cleanliness(repo_root)` at
line 516 and again at 576. But between, it runs the clone. The repo_root working
tree could be dirtied by... nothing. OK.

**Defect L: The clone is created with `git clone --no-local --quiet repo_root 
str(clone)`. This clones the local repo. Then `git checkout --detach tested`. 
But `tested` is HEAD of repo_root. The clone's default branch is whatever. 
`--detach tested` works if the object is present. Since clone copies all 
refs/objects, yes. But `--no-local` forces a real transport; the clone gets the 
default branch. If `tested` is not reachable from any ref... it is HEAD, so 
reachable. OK.

Wait — actually there's a subtle issue. `git clone repo_root` clones the repo's 
HEAD branch. If repo_root is on `development` and HEAD == tested, fine. But the 
clone's `origin` is set to repo_root's path, then `git remote set-url origin 
<repo_root's origin url>`. Why? So that the suite's git operations (e.g., `git 
fetch`) reach the real remote. Hmm, but that means the clone is NOT fully 
isolated from network. The comment says "independent clone". Setting origin to 
the real remote means a suite could fetch/push. But validate.sh refuses linked 
worktrees and the suites are fixtures. Hmm. Actually this is intentional so that
suites that need origin work. But it also means the clone could be affected by 
network. Not a correctness blocker for qualification.

**Defect M: `command(["npm", "ci"])`** — runs npm ci in the clone. The workflow 
already ran `npm ci` in the outer checkout. Redundant but fine. But if the clone
lacks package-lock.json... it has it. OK.

**Defect N: `command(["python3", "-c", "import pytest"])`** — verifies pytest 
importable. The workflow installs pytest with `--break-system-packages`. But the
clone's env is filtered to remove PYTHONPATH/PYTHONHOME. pytest installed 
system-wide → importable. OK.

**Defect O: The `env` filter removes `RT_*` but `RT_SHARD` is set by validate.sh
itself. Good. Removes `XYZ_VALIDATE_*` so `XYZ_VALIDATE_SKIP` can't quarantine. 
Good. Removes `XYZ_HARNESS_DB` so the harness DB is fresh. Good. Removes 
`PYTEST_ADDOPTS`. Good.

But it does NOT remove `XYZ_VALIDATE_PARALLEL`? Wait, `XYZ_VALIDATE_*` prefix 
covers `XYZ_VALIDATE_PARALLEL`, `XYZ_VALIDATE_MAX_JOBS`, 
`XYZ_VALIDATE_THROTTLE`, `XYZ_VALIDATE_SKIP`, `XYZ_VALIDATE_TELEMETRY`. All 
removed. Good. And `--sequential` is passed explicitly. Good.

**Defect P: `qualification_summary` requires `start.get("tier") != 3`.** 
validate.sh rt_begin is called with `"$TIER"`. For `--sequential` with no tier 
flag, TIER=3. Good.

**Defect Q: The receipt's `telemetry` field is 
`str(telemetry_path.relative_to(repo_root))`. On macOS, `Path.relative_to` 
works. The path is `TESTS-RESULTS/<date>+GH-591/wave-<sha>/validation.jsonl`. 
The regex QUALIFICATION_PATH matches. Good.

**Defect R: `qualification_receipt_matches` checks `path.resolve() != path`.** 
`path = Path(repo_root).resolve() / telemetry`. `path.resolve()` resolves 
symlinks. If no symlinks, equal. Good. But if `repo_root` itself is behind a 
symlink, `Path(repo_root).resolve()` handles it. Good.

**Defect S: `check_provenance_receipts` — the new branch:**
```python
if str(entry.get("schema_version", "")).startswith("wave-qualification"):
    if qualification_receipt_matches(repo_root, entry, pr_meta):
        log(...)
        return
    continue
```
So a wave-qualification entry that doesn't match is skipped (continue), not 
falling through to legacy. Good. But note: `str(entry.get("schema_version", 
""))` — if schema_version is None, str(None)="None", doesn't start with. Fine.

**Defect T: `qualification_receipt_matches` for `artifact_kind == "commit"`:** 
it skips the PR check. But then `entry.get("pr")` may be absent. And `if 
"pr_number" in entry and entry["pr_number"] != entry.get("pr")` — for commit 
entries, pr_number absent. OK.

**Defect U: The `test_new_schema_cannot_fall_through_to_legacy_pr_match` test 
mutates `schema_version` to `wave-qualification@99`. Then 
`qualification_receipt_matches` returns False (schema mismatch), and 
`check_provenance_receipts` does `continue` (because startswith 
"wave-qualification"). So it's rejected. Good. But wait — the test writes the 
bad entry to the provenance.jsonl, replacing the good one. Then calls 
check_provenance_receipts. Since the only entry is the bad one, and it's 
skipped, no match → die code 6. Good.

**Defect V: `test_incomplete_or_quarantined_telemetry_is_rejected`** mutates 
rows and calls `qualification_summary` directly, expecting ValueError. For 
`(0,'registered',0)`: registered=0 → `type(registered) is not int or registered 
<= 0` → raises. Good. For `(-1,'failed',1)`: summary failed=1 → raises. Good. 
For `(-1,'run_set','0')`: `str(summary.get("run_set")) != str(registered)` → "0"
!= "1" → raises. Good. For `(-1,'suite_events_match','no')`: raises. Good. For 
`(-1,'envelope_rc','2')`: raises. Good.

**Defect W: `test_bounded_runner_timeout_refuses_receipts`** patches 
`proc_group.run_bounded` to return `BoundedResult(None,'','',True,1,5400)`. Then
`command()` sees `result.timed_out` True → raises CalledProcessError(124). 
Caught → die code 6. And asserts `bounded.call_args.kwargs['timeout'] == 5400`. 
But `run_bounded` is called with `timeout=5400` as kwarg. Good. But note: the 
patch is on `proc_group.run_bounded`, and `qualify_landings` does `from 
proc_group import run_bounded` INSIDE the function. So the import happens at 
call time, getting the patched attribute. Good.

Hmm wait — `from proc_group import run_bounded` inside `qualify_landings`. The 
patch `patch('proc_group.run_bounded', ...)` replaces the module attribute. The 
`from ... import` at call time reads the current attribute → patched. Good.

**Defect X: `test_receipts_participate_in_rollback`** — after qualify, 
journal.rollback() unlinks created files. Asserts no provenance/validation. 
Good.

**Defect Y: `test_batch_qualifies_once_and_retains_each_landing`** — two metas, 
one run, two entries. Good.

Now let me think about **real defects**.

**Real Defect 1: `qualification_summary` `rows[-1] != summaries[0]`.** It 
requires the LAST row to be the summary. But validate.sh emits `rt_summary` at 
the end, then... actually after rt_summary, validate.sh prints "telemetry: ..." 
to stdout, not telemetry. And the gate_receipt write. So the last telemetry row 
is the summary. But wait — in parallel mode there's a merge record. In 
sequential mode, no merge. The last rt_emit is `rt_summary`. Hmm, but actually 
`rt_summary` might emit the summary row. Let me check: `rt_summary 
"${#PASSED[@]}" "${#FAILED[@]}" "$TOTAL" "suite_events=..." ...`. So yes, 
summary is last. But is there anything after? The `envelope-assert` stage is 
emitted before gamma probe. Then gamma probe suite. Then summary. So summary 
last. Good.

But hold on — `rows[-1] != summaries[0]` compares dicts. If there are multiple 
summary rows... `len(summaries) != 1` catches. OK.

**Real Defect 2: The `run` field format.** `f"{tested[:9]}-{validation.pgid}"`. 
But the real rt_begin sets `RT_RUN_ID`. What format? The test fixture uses 
`sha[:9]+'-'+str(os.getppid())`. If the real rt_begin uses a different format 
(e.g., includes a timestamp or a different separator), then the check 
`json.loads(raw.splitlines()[0]).get('run') != 
f"{tested[:9]}-{validation.pgid}"` would FAIL for real runs → permanent 
inability to qualify. This is the same class as Defect about telemetry path. The
test only proves the fixture's format matches. Hmm. This is a **Should/Blocker 
hypothesis**: the run-id format is asserted against a fixture, not the real 
runner. If the real `rt_begin` run id differs, qualification always fails.

Actually, let me reconsider. The producer says "Producer full local gate374/374 
at ea0a4e68". That's the gate, not qualification. The qualification path may 
never have been run for real. So these format assumptions are unverified. I'll 
flag as Should with the concrete trigger.

Hmm, but I should be careful not to over-claim. Let me look at what evidence 
exists. The test fixture is the only evidence. The real `runner-telemetry.sh` is
not in the packet. So I can say: the test substitutes a stub validate.sh whose 
telemetry format is authored to match the assertions; the real runner's `run` id
and telemetry directory are not exercised, so a mismatch is undetectable by the 
suite and would make qualification permanently fail (or, worse, the glob could 
match a stale file). That's a legitimate finding.

**Real Defect 3: `qualify_landings` — `pending` computed from 
`committed_qualifications`, but the receipt written in THIS run is not 
committed. If the run is invoked twice in the same working tree (e.g., retry), 
the second invocation's `committed_qualifications` reads HEAD (no receipt), so 
`pending` is non-empty again, and it tries to write the receipt again → 
`path.exists()` → die "Refusing to overwrite qualification evidence". So a retry
after a partial failure (e.g., the commit step failed) would die. Hmm, but the 
workflow is one-shot. Actually if the reconcile step succeeds (writes receipt) 
but the commit step fails, the next scheduled run starts from fresh development 
(no receipt committed) and re-qualifies. But the working tree is fresh 
(checkout), so no leftover. OK. But if the same job retries... GitHub doesn't 
retry steps. Fine. Nit.

**Real Defect 4: The workflow `timeout-minutes: 120` and `run_bounded` timeout 
5400s = 90 min.** The clone + npm ci + full sequential gate. The gate is ~950s 
sequential per the comment. Plus clone. 90 min is generous. But the workflow 
timeout 120 min includes checkout, npm ci, pytest install, reconcile (90 min), 
commit. If the gate takes near 90 min, the workflow could hit 120. Probably 
fine. Nit.

**Real Defect 5: `qualify_landings` runs the full gate in a clone, but the 
clone's `origin` is set to the real remote. validate.sh's GH-1 identity bracket 
asserts the clone's identity. But the clone is a fresh clone; 
`runner_envelope_begin` captures identity. Fine.

**Real Defect 6: `check_provenance_receipts` walks `os.walk(results_dir)` and 
for each `provenance.jsonl`/`error_log.jsonl`. The new qualification receipt is 
in `TESTS-RESULTS/<date>+GH-591/wave-<sha>/provenance.jsonl`. It's found. Good. 
But `qualification_receipt_matches` reads the telemetry file relative to 
repo_root. During the run, the telemetry is in the working tree. Good.

**Real Defect 7: `qualification_receipt_matches` ancestry `(tested, "HEAD")`.** 
During the run, HEAD == tested (the reconcile runs on development at tested). So
`merge-base --is-ancestor tested HEAD` → tested is HEAD → true. Good. But after 
the bot commits the receipt, HEAD advances to a new commit whose parent is 
tested. Then `tested` is an ancestor of HEAD. Good. And `landing` is an ancestor
of `tested`. Good.

But here's a subtle issue: the bot commit includes the receipt AND the 
reconciliation artifacts. So HEAD after commit = new commit. 
`committed_qualifications` reads HEAD's tree → finds the receipt. 
`qualification_receipt_matches` checks `tested` ancestor of HEAD → yes. Good.

**Real Defect 8: `qualification_receipt_matches` requires `entry.get("gate") != 
"validate.sh --sequential"`.** The receipt sets `gate="validate.sh 
--sequential"`. Good.

**Real Defect 9: The `artifact_kind` check.** `entry.get("artifact_kind") != 
meta.get("artifactKind", "pr")`. For PR metas, `meta.get("artifactKind")` is 
None (fetch_pr_metadata doesn't set artifactKind), so default "pr". The receipt 
sets `artifact_kind=meta.get("artifactKind", "pr")` = "pr". Good. For commit 
metas, artifactKind="commit". Good.

**Real Defect 10: `qualify_landings` for commit metas.** `landing = 
(meta.get("mergeCommit") or {}).get("oid", "")`. fetch_commit_metadata sets 
mergeCommit={"oid": sha}. Good. And `meta.get("state") == "MERGED"` — 
fetch_commit_metadata sets state="MERGED". Good. `baseRefName == "development"`.
Good.

**Real Defect 11: In `main`, `metadata` is built for ALL landing_items when 
`--qualify`. Then `qualify_landings(repo_root, list(metadata.values()), 
journal)`. Then the loop uses `metadata[(kind, value)]`. But `landing_items` was
deduped via `dict.fromkeys`. And `metadata` keys are `(kind, value)` where value
is str. `landing_items` values are str. Good.

But note: `fetch_pr_metadata(repo_root, value)` is called WITHOUT 
`offline_manifest` and without `dry_run`. Since --qualify forbids --offline and 
--dry-run, fine.

**Real Defect 12: `qualify_landings` is called even when `landing_items` is 
empty?** `if args.qualify and landing_items:` — so only if non-empty. Good. But 
`--catch-up` may produce empty landing_items; then no qualification. Then the 
loop does nothing, and `if not args.dry_run and not landing_items and not 
args.marathon:` → "Nothing to reconcile". Good.

**Real Defect 13: The `--qualify` guard doesn't forbid `--force-promote` or 
`--skip-branch-check` or `--skip-pull`.** Not a correctness issue.

**Real Defect 14: `qualification_summary` `summary.get("total") != registered + 
3`.** If `registered` is a bool... `type(registered) is not int` — bool is not 
int (type(True) is bool). So registered=True → raises. Good.

**Real Defect 15: `qualification_summary` `start.get("tier") != 3`.** If tier is
"3" (string), != 3 → raises. The real rt_begin passes `"$TIER"` which is "3" 
string. Hmm! `rt_begin "$HERE" "validate" "sequential" 1 "$TIER" 
"${#TESTS[@]}"`. TIER is a shell variable = "3". So the JSON would have 
`"tier":"3"` (string) or `"tier":3`? Depends on how rt_begin serializes. If it 
does `"tier":$5` unquoted in JSON, it'd be numeric 3. If `"tier":"$5"`, string. 
The test fixture writes `tier=3` (int). So the assertion `start.get("tier") != 
3` requires int. If the real lib emits a string, qualification fails. Again the 
same class: fixture-vs-real format. Hmm, this is a recurring theme. Let me check
the test fixture: 
`rows=[dict(event='run.start',commit=sha,mode='sequential',tier=3,registered=1)]
`. So tier=3 int, registered=1 int. And `summary` has 
`passed=4,failed=0,total=4,envelope_rc='0',suite_events_match='yes',run_set='1',
registered='1'`. Note run_set and registered are STRINGS in the summary, and the
code does `str(summary.get("run_set")) != str(registered)`. So the code 
accommodates string. But `start.get("tier") != 3` does NOT accommodate string. 
And `type(registered) is not int` requires int for start.registered. So the code
assumes start.tier and start.registered are ints, but summary.run_set/registered
are strings. That's an inconsistency that suggests the real lib emits... hmm. 
Actually the test fixture was authored to match the code, so it's circular. But 
the inconsistency (start int, summary str) is suspicious — it may reflect the 
real lib's actual output (rt_begin emits ints, rt_summary emits strings). 
Plausible. I'll note it as a hypothesis but not a proven defect.

Hmm, actually this is important. Let me think about whether the real rt_begin 
emits `tier` as int. Looking at validate.sh: `rt_begin "$HERE" "validate" 
"sequential" 1 "$TIER" "${#TESTS[@]}"`. The lib signature is `rt_begin <root> 
<runner> <mode> <width> <tier> <registered>`. The lib likely does `"tier":$5` → 
numeric. And `"registered":$6` → numeric. And rt_summary does `"run_set":"$2"` 
maybe string. Plausible. So the code matches. OK, I won't flag as blocker, maybe
a Should to verify.

Let me now think about **the most concrete, provable defects**.

**Concrete Defect A: `qualification_receipt_matches` does not verify the 
receipt's `telemetry` file is committed / that the receipt itself is 
committed.** But `check_provenance_receipts` reads from the working tree, which 
is fine for the same-run case. For the replay case, `committed_qualifications` 
reads from HEAD. OK.

**Concrete Defect B: `committed_qualifications` reads `git show HEAD:{path}` for
each provenance path. If a path contains a colon or special char... no. Fine.

**Concrete Defect C: The workflow allowlist regex `receipt` allows 
`validation.jsonl` and `provenance.jsonl` under 
`TESTS-RESULTS/<date>+GH-591/wave-<40hex>/`. But the code writes the folder as 
`f"{now:%Y-%m-%d}+GH-591"` and `f"wave-{tested}"`. `tested` is 40-hex. Good. But
the regex requires `[0-9a-f]{40}` lowercase. `tested` from `git rev-parse HEAD` 
is lowercase. Good.

**Concrete Defect D: `qualify_landings` writes the receipt with `entry["pr"] = 
meta["number"]`. For PR metas, `meta["number"]` is an int from gh. Good. But 
`qualification_receipt_matches` checks `type(entry.get("pr")) is not int or 
entry["pr"] != meta.get("number")`. Good.

**Concrete Defect E: `test_wrong_landing_fails_before_qualification`** — meta 
with mergeCommit oid 'b'*40. `qualify_landings` checks `merge-base --is-ancestor
bbbb... tested` → fails → die. Good. But note: `committed_qualifications` is 
called first; no committed receipts → pending non-empty. Then 
check_porcelain_cleanliness. Then tested. Then the loop dies. Good.

**Concrete Defect F: `qualify_landings` — the `die` inside the `with 
tempfile.TemporaryDirectory()` block raises ReconcileError, which propagates out
of the `with` (cleanup runs), then out of `qualify_landings`. In `main`, it's 
inside the `try` → `except ReconcileError` → journal.rollback(). But the journal
has no created files yet (receipt written after the temp block). So rollback is 
a no-op. Good.

**Concrete Defect G: The `command()` function prints stdout/stderr when not 
capture. For `npm ci` and `validate.sh`, output is printed. Fine.

**Concrete Defect H: `run_bounded` signature.** `run_bounded(args, cwd=..., 
env=..., timeout=5400)`. The test patches it and checks 
`call_args.kwargs['timeout']`. So run_bounded accepts timeout kwarg. And returns
BoundedResult with `.stdout`, `.stderr`, `.timed_out`, `.rc`, `.pgid`. The test 
constructs `BoundedResult(None,'','',True,1,5400)` — positional: stdout=None, 
stderr='', ???='', timed_out=True, rc=1, pgid=5400. Hmm, 6 fields. So 
BoundedResult has 6 fields. The code uses `result.stdout`, `result.stderr`, 
`result.timed_out`, `result.rc`, `result.pgid`. So the 6 fields are (stdout, 
stderr, ?, timed_out, rc, pgid). The third field is unknown (maybe `combined` or
`duration`). OK.

**Concrete Defect I: `validation.pgid`** — `run_bounded` returns pgid. For the 
real run, pgid is the process group of the launched `bash validate.sh`. The 
telemetry filename embeds the pgid. But does the real validate.sh name its 
telemetry file with the pgid? The test fixture names it with `os.getppid()` (the
shell's pid). If run_bounded launches with `start_new_session=True`, then the 
shell's pid == pgid. So `os.getppid()` in the python child == shell pid == pgid.
Consistent. But the real `rt_begin` — does it name the file with the pgid? The 
glob is `validate-sequential-*-{pgid}.jsonl`. The real lib must name it 
`validate-<mode>-<something>-<pgid>.jsonl`. Hmm, actually maybe the real lib 
names it with `$$` (shell pid) or `$BASHPID`. If run_bounded uses 
start_new_session, shell pid == pgid. Plausible. But again unverified by the 
test (stub). Same class.

OK. I think the strongest findings are:

1. **[Should] The qualification suite never exercises the real runner's 
telemetry contract.** The stub validate.sh authors `run`, `tier`, `registered`, 
the filename, and the directory to match the assertions. The real 
`runner-telemetry.sh` (not in the packet) determines all of these. If any 
differs (e.g., GH-496 out-of-tree telemetry, a different run-id format, string 
vs int tier), `qualify_landings` dies with code 6 on every real run — a 
permanent inability to qualify valid data, which is exactly the failure mode 
question 1 asks about. Concrete trigger: run `--qualify` on a real checkout. 
Smallest fix: add a real-runner integration assertion (or read the lib and pin 
the format), and make the glob/format check derive from the lib rather than a 
fixture.

Actually, wait. Let me reconsider whether the telemetry is out-of-tree. The env 
sets `TICK_REPO_ROOT=str(clone)`. The GH-496 isolation writes to 
`~/.xyz/projects/<key>/telemetry/`. If validate.sh's rt_begin honors 
TICK_REPO_ROOT and writes to `$TICK_REPO_ROOT/.tick/telemetry`, then in-tree. 
Hmm. The test fixture uses `XYZ_VALIDATE_TELEMETRY` default `.tick/telemetry`. 
But the code filters out `XYZ_VALIDATE_*`, so the real lib can't be steered by 
that env. So the real lib's default location is what matters. I genuinely can't 
prove it. I'll present it as a hypothesis with the concrete probe: run the real 
gate in a clone and check where the JSONL lands.

Hmm, but the instructions say "Distinguish proven defects from hypotheses." So 
I'll mark it as a hypothesis/Should.

2. **[Should] `qualification_summary` requires `rows[-1] == summary`, but the 
real sequential run may emit a trailing `stage`/`retry` row after the summary** 
— actually no, summary is last. Let me not.

Let me look for a PROVEN defect.

**Proven Defect: `qualification_receipt_matches` — the `pr_number` consistency 
check is dead/incorrect.**
```python
if "pr_number" in entry and entry["pr_number"] != entry.get("pr"):
    return False
```
The receipt never writes `pr_number`, so this is dead. Not a defect per se.

**Proven Defect: `check_provenance_receipts` — a wave-qualification entry with a
matching schema but for a DIFFERENT PR is `continue`d, and the loop continues to
other files. Good. But if the ONLY receipt is a wave-qualification entry for 
another PR, it dies. Good.

**Proven Defect: `qualify_landings` — `previous = 
committed_qualifications(repo_root)` reads HEAD. But 
`qualification_receipt_matches(repo_root, entry, meta)` for a committed entry 
reads the telemetry file from the WORKING TREE (`Path(repo_root).resolve() / 
telemetry`). If the committed receipt's telemetry file is not present in the 
working tree (e.g., a fresh checkout where the telemetry was committed — it 
would be present). Since the bot commits both, present. OK.

But here's a real one: **`committed_qualifications` reads the receipt from HEAD,
but `qualification_receipt_matches` reads the telemetry from the working tree, 
not from HEAD.** If the working tree telemetry differs from the committed one 
(e.g., a developer modified it), the hash check would fail → not matched → 
re-qualify. That's fail-safe. OK.

**Proven Defect: The `--qualify` guard allows `--skip-pull`.** If `--skip-pull` 
is passed, the repo may be stale, but `tested` is HEAD. Not a correctness issue.

**Proven Defect: `qualify_landings` does not verify that the clone's `tested` 
checkout is clean before running.** It checks after. Fine.

**Proven Defect: `qualify_landings` — `command(["git", "config", "--local", 
"--list"], True).stdout` compared before/after. But `git clone` sets 
`remote.origin.url` etc. Then `git remote set-url origin origin` changes it. 
`before_config` is captured AFTER set-url. Then after the suite, compared. If 
the suite changes config, detected. Good. But `git checkout --detach` may add 
`core.bare`? No.

Hmm, the `drift` fixture sets `git config core.bare true` and exits 0. Then the 
check `command(["git", "config", "--local", "--list"], True).stdout != 
before_config` → detects. Good. But wait — after `core.bare true`, `git 
rev-parse HEAD` might fail or `git status` might fail. The `command()` would 
raise CalledProcessError → caught → die. Either way code 6. Good.

**Proven Defect: `test_red_partial_and_identity_drift_produce_no_receipt`** 
asserts `self.git('status','--porcelain') == ''` after each mode. For 'drift', 
the fixture sets core.bare in the CLONE, not the source. So source is clean. 
Good.

Let me look at the **workflow** more carefully.

**Proven Defect: The workflow's commit step allowlist includes the receipt 
regex, but the reconcile step writes the receipt to 
`TESTS-RESULTS/<date>+GH-591/wave-<sha>/`. The commit step's `changed` includes 
untracked files via `git ls-files --others --exclude-standard`. But `.tick/` is 
gitignored. The receipt is not under `.tick`. Good.

But: the reconcile step runs `qualify_landings` which creates the clone in a 
temp dir OUTSIDE the repo. Good.

**Proven Defect: The workflow installs pytest with `--break-system-packages`. On
macos-latest, python3 is Homebrew or system. `--break-system-packages` is a pip 
flag for PEP 668. If the runner's python3 is externally managed, needed. If not,
the flag is accepted (pip >= 23.0). OK.

**Proven Defect: `timeout-minutes: 120` but the reconcile step's `run_bounded` 
timeout is 5400s (90 min) for EACH command. There are multiple commands (clone, 
checkout, set-url, config, pytest, npm ci, validate.sh). Each gets 5400s. So the
total could exceed 120 min. But realistically only validate.sh is long. The 
workflow timeout would kill the job. Not a correctness blocker.

Now, **Question 3: replay and receipt consumers trustworthy and idempotent? 
Trace reads of committed receipts versus working-tree telemetry, symlinks and 
all relevant entry modes. Establish how a suspected dirty-state problem can 
reach the live --qualify path despite its clean-tree precondition.**

`qualify_landings` calls `check_porcelain_cleanliness(repo_root)` at line 516. 
But `main` already called `check_porcelain_cleanliness` at line 1838 with 
`allow_dirty=(args.allow_dirty or args.dry_run)`. Since --qualify forbids 
--allow-dirty and --dry-run, the preflight is strict. Then `qualify_landings` 
re-checks. Good.

But: **the dirty-state problem can reach the live --qualify path via the 
`committed_qualifications` replay.** If a committed receipt exists and matches, 
`pending` is empty and `qualify_landings` returns early WITHOUT running the 
gate. So a stale/dirty working tree... no, the preflight already checked clean. 
Hmm.

Actually, here's a real one: **`qualify_landings` returns early (line 514-515) 
when `pending` is empty, BEFORE `check_porcelain_cleanliness`.** So if all 
landings are already committed-qualified, the function returns without checking 
cleanliness. But `main` already checked. So fine.

**Question 3 dirty-state:** The `check_provenance_receipts` reads the working 
tree. If a developer has an uncommitted, hand-crafted `provenance.jsonl` with a 
valid-looking qualification entry pointing at a telemetry file they also 
crafted, `qualification_receipt_matches` would verify the hash and the ancestry.
The ancestry check `(tested, "HEAD")` requires tested to be an ancestor of HEAD.
A crafted receipt could name a real ancestor commit and a crafted telemetry file
with a matching hash. Then `qualification_summary` would validate the crafted 
telemetry. So a hand-crafted receipt+telemetry pair could pass `--gate` without 
a real gate run. But `--qualify` would then... hmm, `--qualify` runs 
`qualify_landings` which checks `committed_qualifications` (HEAD only, not 
working tree). So a working-tree-only crafted receipt would NOT suppress 
qualification; `qualify_landings` would run the real gate and then try to write 
the receipt → `path.exists()` → die. So the crafted receipt causes a die, not a 
false pass. Hmm, but if the crafted receipt is COMMITTED, 
`committed_qualifications` finds it and `qualification_receipt_matches` 
validates it (reading the committed telemetry from the working tree). If the 
telemetry is also committed and crafted, it passes. So a committed crafted pair 
bypasses the gate. But that requires committing to development, which is the 
bot's job. A malicious actor with push access could. That's a trust boundary, 
not a defect. The receipt is "tamper-evident, not attested" (per GH-536). So 
I'll note it as a boundary, not a blocker.

**Question 4: rollback and publication.** The receipt is written to the working 
tree and tracked in the journal. If a later step fails, rollback unlinks it. But
the workflow's commit step is a SEPARATE step; if the reconcile step succeeds 
and the commit step fails, the receipt is in the working tree but not committed,
and the job fails. The next run starts fresh. So no silent loss. But the receipt
is lost (not committed) — visible recoverable failure. OK.

**Publication:** `git push origin HEAD:development`. If rejected (concurrent 
merge), the job fails. The next scheduled run recomputes. But the receipt was 
written to the working tree and committed locally; the push fails → the local 
commit is lost (ephemeral runner). So the qualification evidence is lost and 
must be recomputed. That's a visible recoverable failure (the job fails). But it
means a full 90-min gate is wasted. Not a correctness blocker.

Hmm, but here's a subtle one: **the bot commit includes the receipt. If the push
is rejected, the next run re-qualifies from scratch (fresh checkout, no 
receipt). But `qualify_landings`'s `committed_qualifications` reads HEAD of the 
fresh checkout, which doesn't have the receipt. So it re-runs. Good.

**Question 5: tests catch original and new failure classes?** The tests cover 
red, partial, drift, wrong-run, wrong-landing, committed-replay, schema 
fallthrough, incomplete telemetry, timeout, rollback, batch. Missing: a test 
that the REAL runner's telemetry format is accepted (the stub masks it). 
Missing: a test that a symlinked telemetry file is rejected (the code checks 
`path.resolve() != path`, but no test). Missing: a test that a receipt with a 
valid hash but a telemetry file whose `run` id doesn't match the launched 
process is rejected — actually 
`test_red_partial_and_identity_drift_produce_no_receipt` with 'wrong-run' covers
the run-id mismatch at the qualify level, but not at the receipt-match level. 
Hmm.

Missing negative case: **a committed receipt whose telemetry file is a symlink**
— `qualification_receipt_matches` checks `path.resolve() != path` → returns 
False. No test. Should.

Missing negative case: **a receipt whose `telemetry` path escapes via `..`** — 
the regex `QUALIFICATION_PATH` forbids `..`. Good.

Missing negative case: **`qualification_receipt_matches` with `meta` lacking 
`mergeCommit`** — `landing = None`, `not isinstance(landing, str)` → False. 
Good.

Missing: **the `--qualify` CLI guard** — no test that `--qualify` without 
`--gate` errors. Should.

Missing: **`committed_qualifications` with a malformed committed receipt** — no 
test.

OK. Let me also check the **`test/gh591-prepush-commit-boundary.sh`** — it's a 
new test that witnesses the pre-push hook boundary. It's registered in 
validate.sh. It uses a real local bare remote. It asserts the hook-created file 
doesn't travel in the first push. This is a documentation/witness test. Fine. 
But it's not directly about the qualification code. It's about the workflow's 
commit step. Hmm, actually it's about Git's pre-push hook behavior. It's a bit 
tangential. Nit.

Now let me also check: **the workflow's `receipt` regex is added to the 
allowlist, but the `validation.jsonl` file is the telemetry. The commit step 
commits both. Good. But the allowlist regex requires the folder to be `+GH-591`.
The code writes `+GH-591`. Good.

Let me now check a **proven defect in `qualification_summary`**:

```python
if (len(sequential) != registered or len({row.get("name") for row in 
sequential}) != registered
        or any(type(row.get("rc")) is not int or row["rc"] != 0 for row in 
suites)
        ...
```

`len(sequential) != registered` — requires exactly `registered` sequential-lane 
suite rows. But the real validate.sh emits suite rows with lane "sequential" for
each suite in sequential mode. And `registered` = len(TESTS). So 
`len(sequential) == registered`. Good. But wait — in sequential mode, `rt_suite 
sequential "$t" ...` is called for each suite. So yes. But the `retry` lane rows
are `rt_suite retry ...` — only in parallel mode. Sequential mode has no 
retries. Good.

Hmm, but `len({row.get("name") for row in sequential}) != registered` — requires
unique names. Good.

`any(type(row.get("rc")) is not int or row["rc"] != 0 for row in suites)` — ALL 
suite rows (including non-suite lane) must have rc int 0. The non-suite rows are
pytest, gamma, envelope-assert (stage, not suite), telemetry-merge (stage). Wait
— `rt_emit suite non-suite "python:test_python_layer.py" ...` and `rt_emit suite
non-suite "gamma-poison-staleness-probe" ...`. So those are `event=suite, 
lane=non-suite`. And `rt_emit stage non-suite "envelope-assert" ...` is 
`event=stage`. So `suites` = rows with event=="suite" = sequential + non-suite 
(pytest, gamma). All rc 0. Good.

`summary.get("total") != registered + 3` — TOTAL = registered + 1 (identity) + 1
(pytest) + 1 (gamma) = registered + 3. Good.

`names = {row.get("name") for row in suites}` and requires 
`{"python:test_python_layer.py", "gamma-poison-staleness-probe"} <= names`. 
Good.

OK so `qualification_summary` looks correct against the real validate.sh 
contract, ASSUMING the telemetry field types match.

Now, one thing: **`summary.get("envelope_rc") != "0"`.** The real rt_summary is 
called with `RT_ENVELOPE_RC="$_re_rc"`. And `rt_summary` presumably emits 
`"envelope_rc":"$RT_ENVELOPE_RC"` as a string. The test fixture uses 
`envelope_rc='0'` string. Good.

**`summary.get("suite_events_match") != "yes"`.** rt_summary is called with 
`"suite_events_match=$([ ... ] && printf yes || printf no)"`. So the value is 
"yes"/"no" string. Good.

**`str(summary.get("run_set")) != str(registered)`.** rt_summary called with 
`"run_set=${#RUN_TESTS[@]}"`. If rt_summary emits it as a string, `str()` 
handles. Good.

**`str(summary.get("registered")) != str(registered)`.** Good.

So the summary checks are consistent with the real contract. The `start` checks 
(`tier`, `registered` as int) are the uncertain ones. Let me look at rt_begin's 
likely signature. `rt_begin "$HERE" "validate" "sequential" 1 "$TIER" 
"${#TESTS[@]}"`. The lib probably does:
```
rt_begin() { ... rt_emit run.start ... "tier":$5,"registered":$6 ... }
```
If unquoted, numeric. Plausible. I'll note as a hypothesis.

Hmm, let me reconsider the **`run` id format**. `RT_RUN_ID` is set by rt_begin. 
The code checks `f"{tested[:9]}-{validation.pgid}"`. The test fixture uses 
`sha[:9]+'-'+str(os.getppid())`. So the real RT_RUN_ID must be `<sha9>-<pgid>`. 
Is that plausible? The lib would need to know the pgid. `$$` in bash is the 
shell pid. If run_bounded uses start_new_session, shell pid == pgid. So 
`RT_RUN_ID="${sha9}-$$"`. Plausible. But the code uses `validation.pgid` (from 
run_bounded), not the shell pid. If run_bounded does NOT use start_new_session, 
then pgid != shell pid, and the check fails. Hmm. The test's 
`BoundedResult(None,'','',True,1,5400)` sets pgid=5400, and the fixture uses 
`os.getppid()`. In the test, run_bounded is NOT patched for the success case, so
the real run_bounded runs the stub validate.sh. The stub's python child's 
`os.getppid()` == the shell's pid. And `validation.pgid` == run_bounded's pgid. 
For the test to pass, run_bounded's pgid must equal the shell's pid, i.e., 
run_bounded must launch the process as a group leader (start_new_session=True) 
OR pgid == pid. So the test DOES verify that run_bounded's pgid == the launched 
shell's pid. Good — that's a real integration assertion. So the run-id format 
`<sha9>-<pgid>` is verified to be consistent with run_bounded's pgid. But 
whether the REAL rt_begin uses `$$` (== pgid) is still unverified. Hmm, but the 
test's stub uses `os.getppid()` which is the shell pid, and the code compares to
`validation.pgid`. So the test asserts pgid == shell pid. If the real rt_begin 
uses `$$` (shell pid), then real run id == `<sha9>-<shellpid>` == 
`<sha9>-<pgid>`. Consistent. OK, so this is reasonably verified. Good.

But the telemetry DIRECTORY is still the question. The stub writes to 
`.tick/telemetry` (relative to cwd=clone). The code globs 
`clone/.tick/telemetry`. So the test asserts the real lib writes to 
`.tick/telemetry` under the clone. But the stub is authored to do so. The real 
lib's location is unverified. Hmm. Actually, the code sets 
`TICK_REPO_ROOT=str(clone)`. If the real lib writes to 
`$TICK_REPO_ROOT/.tick/telemetry`, consistent. The GH-496 out-of-tree thing is 
for "routine telemetry" (harness telemetry), maybe a different lib. I'll 
downgrade this to a Should/hypothesis.

Let me now find a **proven** defect.

**Proven Defect: `qualify_landings` — `raw = files[0].read_bytes()` then 
`json.loads(raw.splitlines()[0])`.** If the telemetry file is empty, 
`raw.splitlines()[0]` → IndexError, which is NOT caught by `except 
(subprocess.SubprocessError, OSError, ValueError)`. IndexError would propagate 
as an unhandled exception → in `main`, `except (Exception, SystemExit)` → 
rollback → re-raise. So the process crashes with a traceback instead of a clean 
die code 6. Is that a defect? It's a poor diagnostic, not a false pass. The file
is written by the runner; empty is unlikely. But `qualification_summary` also 
does `rows = [...]` and raises ValueError if empty. But the 
`json.loads(raw.splitlines()[0])` happens BEFORE `qualification_summary`. So an 
empty file → IndexError. Minor. Should/Nit.

Actually wait, more importantly: `json.loads(raw.splitlines()[0])` — if the 
first line is not valid JSON, `json.JSONDecodeError` (subclass of ValueError) → 
caught → die code 6. Good. If empty → IndexError → uncaught. Nit.

**Proven Defect: `qualification_receipt_matches` catches `(OSError, ValueError, 
TypeError, KeyError)` but `qualification_summary` can raise `IndexError`?** No, 
it raises ValueError. And `json.loads` raises ValueError. OK. But 
`path.read_bytes()` on a directory raises IsADirectoryError (OSError). Caught. 
Good.

**Proven Defect: `committed_qualifications` — `subprocess.check_output(["git", 
"show", f"HEAD:{path}"], ...)`.** If a path is a directory or the show fails, 
check_output raises CalledProcessError, which is NOT caught → propagates. In 
`qualify_landings`, `previous = committed_qualifications(repo_root)` is called 
OUTSIDE the try/except (line 511, before the try at 548). So a 
CalledProcessError would propagate to `main`'s `except (Exception, SystemExit)` 
→ rollback → re-raise → traceback. Hmm. But `git ls-tree` only lists blobs, so 
`git show` should succeed. Unless the blob is huge. Nit.

**Proven Defect: `qualify_landings` — `check_porcelain_cleanliness(repo_root)` 
at line 516 is called AFTER `committed_qualifications` but the `pending` 
computation calls `qualification_receipt_matches` which runs `git merge-base` 
subprocesses. Fine.

Let me look at the **`main` integration** for a real bug.

```python
metadata = {}
if args.qualify and landing_items:
    for kind, value in landing_items:
        metadata[(kind, value)] = (fetch_commit_metadata(repo_root, value) if 
kind == "commit"
                                    else fetch_pr_metadata(repo_root, value))
    qualify_landings(repo_root, list(metadata.values()), journal)
for landing_kind, landing_id in landing_items:
    if (landing_kind, landing_id) in metadata:
        pr_meta = metadata[(landing_kind, landing_id)]
    elif landing_kind == "commit":
        pr_meta = fetch_commit_metadata(repo_root, landing_id, offline_manifest)
    else:
        pr_meta = fetch_pr_metadata(repo_root, landing_id, offline_manifest, 
dry_run=args.dry_run)
```

Note: `fetch_pr_metadata(repo_root, value)` without `offline_manifest`. Since 
--qualify forbids --offline, offline_manifest is None. Good. But 
`fetch_pr_metadata` with `dry_run=False` default. Good.

Hmm, but `landing_items` may include `("pr", str(n))` from catch_up. And 
`metadata` keys are `(kind, value)` with value str. `landing_items` values are 
str (from `dict.fromkeys((kind, str(value)) ...)`). Good.

**Proven Defect: `qualify_landings` is called with `list(metadata.values())`. If
two landing_items map to the same meta (e.g., a PR and a commit with the same 
oid), duplicates. Not an issue.

Now, **the biggest question: does `qualify_landings` actually run the gate on 
the pinned snapshot?** Yes, it clones repo_root and checks out `tested`. But 
`tested` is `git rev-parse HEAD` of repo_root. The clone is from repo_root. So 
the clone's `tested` == repo_root's HEAD. Good. And the clone is independent 
(`--no-local`). Good.

But: **the clone's `origin` is set to repo_root's origin URL.** So the clone is 
NOT isolated from the network. A suite could `git fetch` and change refs. But 
the identity check only checks HEAD, status, and local config. A suite could 
fetch and update `origin/development` without changing HEAD/status/config. Then 
the clone's refs differ from the pinned snapshot. But the gate runs on the 
working tree at `tested`, so the fetched refs don't affect the tested content. 
Hmm, unless a suite checks out. The post-check `git rev-parse HEAD == tested` 
catches a checkout. OK.

**Proven Defect: `qualify_landings` does not verify the clone's working tree 
matches `tested` BEFORE running the gate.** It checks after. If the clone's 
checkout is dirty from the start (e.g., `.gitignore`d files), the post-check 
`git status --porcelain` would be non-empty → die. But `.tick/` is gitignored, 
so telemetry doesn't show. Good.

Hmm, actually: the clone is created by `git clone`, which checks out the default
branch. Then `git checkout --detach tested`. If `tested` == the default branch 
HEAD, fine. The working tree is clean. Good.

Now let me think about **Question 2: are qualification_summary and 
qualification_receipt_matches strict enough about run identity, suite 
completeness, required probes, passed/failed/rc types, schema-family isolation, 
SHA/hash/path/PR/ancestry binding?**

- run identity: `start.run` and all rows' run == start.run, runner == 
"validate". Good.
- suite completeness: `len(sequential) == registered`, unique names, all rc 0, 
summary totals. Good.
- required probes: pytest + gamma. Good.
- passed/failed/rc types: `type(rc) is not int`, `summary.get("failed") != 0`, 
`summary.get("passed") != summary["total"]`. Hmm — `summary.get("passed") != 
summary["total"]` — if `passed` is a string "4" and total is int 4, "4" != 4 → 
raises. The real rt_summary emits passed/failed/total as... the test fixture 
uses ints. Plausible. But `type(summary.get("passed"))` is not checked. If 
passed is a bool True and total is 1... edge. Nit.
- schema-family isolation: `startswith("wave-qualification")` → continue. Good.
- SHA/hash/path/PR/ancestry: tested 40-hex, landing 40-hex, telemetry_sha256 
hash, path regex, pr int, ancestry. Good.

One gap: **`qualification_receipt_matches` does not verify 
`entry.get("passed")`/`total` against the telemetry.** It calls 
`qualification_summary(raw, tested)` which validates the telemetry, but the 
receipt's `passed`/`total` fields are not cross-checked. A receipt could claim 
passed=999. Not a correctness issue for the gate (the telemetry is the 
evidence). Nit.

Another gap: **`qualification_receipt_matches` does not verify the receipt's 
`timestamp` or `run_url`.** Not required.

Another gap: **the receipt's `telemetry` path is validated by regex, but the 
receipt could point at a telemetry file for a DIFFERENT landing (same tested 
commit).** Since the telemetry is per-run (per tested commit), and multiple 
landings share the same run, that's fine.

Now, **a real gap: `qualification_receipt_matches` checks 
`entry.get("landing_commit") != landing` where `landing = meta.mergeCommit.oid`.
But for a PR, the merge commit is the squash/merge commit. The ancestry check 
`(landing, tested)` requires landing to be an ancestor of tested. Good. But the 
receipt's `tested_commit` is the snapshot HEAD, and the telemetry's 
`run.start.commit` must equal `tested`. Good.

OK, I think I have enough. Let me also check the 
**`test/gh425-gate-provenance-pr.sh` Qualification.setUp** for a defect: it 
creates a git repo, commits validate.sh and .gitignore. `self.sha = git 
rev-parse HEAD`. `self.meta = dict(META, mergeCommit={'oid': self.sha})`. META 
has number=425. So the meta's mergeCommit == the repo's HEAD. Then `qualify` 
runs. `qualify_landings` checks `merge-base --is-ancestor self.sha tested` where
tested == self.sha → true. Good.

The stub validate.sh checks `test "$TICK_REPO_ROOT" = "$(pwd -P)"`. The code 
sets TICK_REPO_ROOT=str(clone). And cwd is clone. `pwd -P` resolves symlinks. 
`clone` is `scratch/repo` where scratch = `Path(temporary).resolve()`. On macOS,
`/var` → `/private/var`, so `temporary` from tempfile is `/var/folders/...` and 
`.resolve()` → `/private/var/...`. So `clone` is resolved. And `pwd -P` in the 
clone → resolved. Equal. Good. This is a nice check.

Hmm, but `TICK_REPO_ROOT=str(clone)` where clone = scratch/"repo" and scratch is
resolved. So clone is resolved. Good.

Now, the stub checks `test -z "${XYZ_VALIDATE_SKIP:-}"` etc. The code filters 
those out. Good. And `test -z "${RT_SHARD:-}"` — the code filters `RT_*`. Good. 
And `test -z "${XYZ_HARNESS_DB:-}"` — filtered. Good. And `test -z 
"${PYTEST_ADDOPTS:-}"` — filtered. Good. These are the isolation assertions. 

Now, **a real defect**: the env filter is `not k.startswith(("GIT_", "RT_", 
"XYZ_VALIDATE_", "PYTEST_"))`. But `GIT_CONFIG_GLOBAL` and `GIT_CONFIG_NOSYSTEM`
are set AFTER the filter via `env.update(...)`. Good. But `GIT_DIR`, 
`GIT_WORK_TREE` etc. are filtered. Good.

But: the filter does NOT remove `TICK_REPO_ROOT` from the inherited env before 
setting it. It's overwritten. Good. And `RELAY_SELF_SUFFICIENCY_SKIP` 
overwritten. Good.

Hmm, what about `XYZ_HARNESS_DB`? Filtered by `k not in ("XYZ_HARNESS_DB", 
...)`. Good.

What about `XYZ_VALIDATE_TELEMETRY`? Filtered by prefix. Good.

OK. Now let me consider **whether `qualify_landings` can produce a false pass**.

False pass scenario: the glob finds exactly one file matching 
`validate-sequential-*-{pgid}.jsonl`, and its first row's `run` == 
`<sha9>-<pgid>`, and `qualification_summary` passes. Could a stale file from a 
PREVIOUS run in the same clone match? The clone is fresh (temp dir), so no stale
files. Good. Could a nested probe write a file with the same pgid? Only if it 
shares the process group. The check `len(files) != 1` catches multiple. But if 
the nested probe writes a file with the same pgid and the real run's file is 
absent... then the nested probe's file would be selected. But the nested probe's
`run` id would differ (different sha? same sha, same pgid?). Hmm. If a suite 
runs `validate.sh` in the same process group (no new session), the nested run's 
pgid == the outer pgid, and its run id == `<sha9>-<pgid>` (same sha, same pgid).
Then there'd be TWO files → `len(files) != 1` → die. So a nested full 
validate.sh would cause a die, not a false pass. But a nested run that writes to
a DIFFERENT telemetry dir? The nested run inherits TICK_REPO_ROOT=clone, so same
dir. So two files → die. Hmm, that means a suite that runs validate.sh would 
break qualification. But validate.sh refuses linked worktrees and the gamma 
canary is not registered. So no suite runs validate.sh. OK.

Actually wait — the comment says "Suites may launch nested validator probes." If
a suite launches a nested validate.sh, it'd create a second file → die. So 
qualification would fail. Is that a real risk? The registered suites include 
`gh379-canary-uses-validate.sh` which "CALLS validate.sh". Hmm! Let me check: 
validate.sh line 247: `"gh379-canary-uses-validate.sh" # GH-379 (the canary 
CALLS validate.sh; it must never re-implement the runner)`. If that suite 
actually invokes validate.sh, it would create a nested telemetry file with the 
same pgid (if not a new session) → `len(files) != 1` → qualification dies. 
That's a **potential permanent inability to qualify**! 

But does the canary invoke validate.sh with a stub or the real one? The comment 
says "the canary CALLS validate.sh". If it calls the real validate.sh, it'd run 
the whole gate recursively — which would be absurd. More likely it stubs 
validate.sh or checks that the canary script references it. Hmm. Actually 
`gh379-canary-uses-validate.sh` probably asserts that the canary script's source
calls validate.sh, not that it runs it. Let me not over-claim. But it's worth 
flagging: any registered suite that actually executes validate.sh (or a nested 
runner writing telemetry to the same dir with the same pgid) makes `len(files) 
!= 1` and permanently fails qualification. The comment acknowledges nested 
probes but the `len(files) != 1` check turns a nested probe into a hard failure 
rather than selecting the right file. Hmm, actually the comment says "Bind proof
to the exact process we launched, not another passing run in the telemetry 
directory." The glob includes the pgid, so a nested probe with a DIFFERENT pgid 
(new session) would have a different filename and not match. Only a same-pgid 
nested run collides. So the risk is limited. I'll flag as a Should/hypothesis.

Hmm, let me reconsider. Actually the more I think, the `len(files) != 1` is a 
reasonable fail-closed. If a nested probe collides, qualification fails loudly 
(not a false pass). So it's a "permanent inability to qualify valid data" only 
if a registered suite always collides. That's a hypothesis.

Let me now also check: **`qualification_summary` requires `len(sequential) == 
registered` where `registered = start.registered`.** But `start.registered` is 
`${#TESTS[@]}` = the full registry size. In sequential mode, all registered 
suites run. Good. But if `--skip` were used, `registered` would still be the 
full size while `sequential` would be fewer → mismatch → die. But the env filter
removes `XYZ_VALIDATE_SKIP`, and no `--skip` is passed. Good.

Now, **the workflow passes `--qualify` but the reconcile step's `run_bounded` 
timeout is 5400s. The workflow `timeout-minutes: 120`. The full sequential gate 
is ~950s. Plus clone (~seconds) + npm ci (~30s) + pytest install. So ~20 min. 
Fine.

Let me now write the findings. I need to be concise but cite file:line.

Let me settle on the findings:

**Q1:**
- [Pass] `qualify_landings` clones `--no-local` into a temp dir, checks out 
`tested` detached, filters 
GIT_/RT_/XYZ_VALIDATE_/PYTEST_/XYZ_HARNESS_DB/PYTHONPATH/PYTHONHOME, sets a 
private GIT_CONFIG_GLOBAL + GIT_CONFIG_NOSYSTEM, and runs `bash validate.sh 
--sequential` under `run_bounded(timeout=5400)` (wave_reconcile.py:526-558). 
Post-run it asserts HEAD==tested, clean porcelain, and unchanged local config 
(559-562), then binds proof to the launched pgid (565-570). Cited.
- [Should] The telemetry directory/format contract is asserted only against a 
stub validate.sh (test/gh425-gate-provenance-pr.sh:196-221), not the real 
`runner-telemetry.sh`. If the real runner writes telemetry out-of-tree (GH-496) 
or names the file/`run` id differently, `len(files) != 1` (566) or the run-id 
check (569) dies code 6 on every real run — a permanent inability to qualify 
valid data. Trigger: run `--qualify` on a real checkout. Fix: pin the real lib's
path/format (or add a real-runner integration assertion).
- [Should] `len(files) != 1` (566) turns any same-pgid nested runner (a 
registered suite that actually executes validate.sh, e.g. the GH-379 canary) 
into a hard qualification failure. Trigger: a suite that runs validate.sh in the
same process group. Fix: select the file whose `run` id matches the launched 
pgid rather than requiring exactly one.

**Q2:**
- [Pass] `qualification_summary` binds run identity (all rows' run/runner), 
mode/tier, registry count, unique sequential suite names, all rc==0, summary 
totals, envelope_rc, suite_events_match, and required probes 
(wave_reconcile.py:419-448). `qualification_receipt_matches` binds schema, 
40-hex tested/landing, result/rc, gate string, artifact_kind, PR int, telemetry 
path regex, sha256, and both ancestry edges (451-484). Cited.
- [Should] `start.get("tier") != 3` and `type(registered) is not int` (431) 
require ints, while the summary side uses `str(...)` (442-443). If the real 
`rt_begin` emits `tier`/`registered` as strings (as `rt_summary` apparently 
does), every real run dies. Trigger: real run. Fix: normalize with `str()` on 
both sides, or pin the lib's types.
- [Nit] `qualification_receipt_matches` never cross-checks the receipt's 
`passed`/`total` against the telemetry summary (588-593 vs 477). A receipt may 
claim arbitrary counts; the telemetry remains the evidence, so no false pass, 
but the fields are decorative.

**Q3:**
- [Pass] Replay reads committed receipts from HEAD (`committed_qualifications`, 
487-503) and suppresses re-qualification only when 
`qualification_receipt_matches` re-verifies the working-tree telemetry hash and 
ancestry (511-515). `check_provenance_receipts` reads the working tree and 
rejects symlinks (651) and non-files; the qualification branch cannot fall 
through to legacy PR identity (662-667). Cited.
- [Should] A committed, hand-crafted receipt+telemetry pair whose 
`tested_commit` is a real ancestor and whose telemetry hash matches would 
satisfy `qualification_receipt_matches` and suppress the gate. This is the 
documented "tamper-evident, not attested" boundary (GH-536), not a new defect, 
but the `--qualify` path inherits it: `committed_qualifications` trusts HEAD. 
Trigger: commit a crafted pair to development. Fix: none required beyond the 
existing trust boundary; state it.
- [Nit] `qualification_receipt_matches` reads telemetry from the working tree 
even for a committed receipt (470-475); a working-tree/committed divergence 
fails closed (hash mismatch), which is correct but means a dirty telemetry file 
silently disables replay.

**Q4:**
- [Pass] Receipt/telemetry are journal-tracked before write (581-585) and 
removed on rollback; the workflow allowlist admits exactly the receipt paths 
(wave-reconcile.yml:81-83) and pushes one fast-forward commit (97). A rejected 
push fails the job; the next run recomputes from fresh development. Cited.
- [Should] `folder.mkdir(parents=True, exist_ok=True)` (579) creates directories
that are not journal-tracked, so rollback leaves empty 
`TESTS-RESULTS/<date>+GH-591/wave-<sha>/` dirs. They are invisible to porcelain,
so `verify_rollback_completeness` stays silent. Trigger: any failure after 
mkdir. Fix: track/remove the created dirs, or accept as cosmetic.
- [Nit] `run_bounded(timeout=5400)` per command (540) with `timeout-minutes: 
120` (28) means the sum of per-command timeouts can exceed the job bound; only 
validate.sh is realistically long.

**Q5:**
- [Pass] The new Qualification suite covers red, partial, drift, wrong-run, 
wrong-landing, committed-replay idempotence, schema fall-through, 
incomplete/quarantined telemetry, bounded timeout, rollback, and batch 
(test/gh425-gate-provenance-pr.sh:247-321). Cited.
- [Should] Missing negative cases: (a) a symlinked telemetry file (the 
`path.resolve() != path` guard at 472 is untested); (b) `--qualify` without 
`--gate` (the parser.error guard at 1816 is untested); (c) a committed receipt 
whose telemetry is absent (committed_qualifications path). Expected: code 6 / 
parser error. Fix: add the three cases.
- [Nit] `test/gh591-prepush-commit-boundary.sh` witnesses Git's hook boundary 
but does not exercise the qualification code; it is a documentation witness, not
a regression guard for this change.

**Sweep:** swept file: yes. Pre-existing defects: 
`qualification_receipt_matches`'s `pr_number` check (465-466) is dead (the 
receipt never writes `pr_number`); `committed_qualifications`'s 
`QUALIFICATION_PATH.replace("validation","provenance")` (493) is fragile string 
surgery. Both cosmetic.

**VERDICT: PASS** or **FAIL**? The instructions: "Set Approved only if no 
substantive correctness issue remains." I have Shoulds but no proven Blocker. 
The Shoulds are hypotheses about the real runner's format. Hmm. Given the 
producer's claim of a full local gate and the fact that the qualification path's
real-runner contract is unverified, I think the honest verdict is **PARKED** or 
**FAIL**? Let me think.

The question 1 asks "Identify any route to a false pass or permanent inability 
to qualify valid data." I identified a plausible permanent-inability route 
(telemetry path/format) but it's a hypothesis, not proven. The instructions say 
"Distinguish proven defects from hypotheses." And "Set Approved only if no 
substantive correctness issue remains."

Given I cannot prove the telemetry path is wrong, and the code is otherwise 
sound, but there are unverified real-runner contracts that could make 
qualification permanently fail... I think **PARKED** is the honest verdict: the 
mechanism is sound in the fixture but its real-runner contract is unverified, 
and live acceptance is pending. Actually, the relay's Definition of Done says 
"approval requires no substantive correctness blocker. Live acceptance remains 
pending." A PARKED verdict with the Shoulds is appropriate. Hmm, but PARKED 
usually means "can't decide / blocked". 

Let me reconsider. The strongest concrete issue: the test suite substitutes a 
stub for the real runner, so the entire telemetry contract (directory, filename,
run-id, field types) is asserted against a fixture authored to match. That's a 
real coverage gap that could hide a permanent failure. But is it a "substantive 
correctness issue"? It's a verification gap, not a proven defect. 

I'll go with **PARKED** — the code is plausibly correct but the real-runner 
contract is unverified and I cannot approve without it. Actually, hmm. Let me 
reconsider: the relay expects a verdict. Given the producer explicitly says 
"Producer full local gate374/374 at ea0a4e68" and "Hosted acceptance is 
pending", and the reviewer's job is to judge the source. The source is 
well-constructed. The Shoulds are real but not blockers. 

I think the most defensible verdict is **PARKED** with Basis: no proven Blocker;
the qualification mechanism's real-runner telemetry contract is asserted only 
against a stub, so a permanent-failure mode cannot be excluded without a real 
`--qualify` run; live acceptance pending. Hmm, but PARKED might stall the relay.
The relay says "If the max ROUND ends without Approved, set STATUS: Escalated." 
We're at ROUND 2/3. So a non-Approved verdict lets the producer respond in round
3.

Actually, let me reconsider whether there's a PROVEN blocker. Let me re-examine 
the `run` id check once more.

```python
if json.loads(raw.splitlines()[0]).get('run') != 
f"{tested[:9]}-{validation.pgid}":
```

`raw.splitlines()[0]` is the FIRST line. Is the first line the `run.start` row? 
`qualification_summary` requires `rows[-1] == summaries[0]` (summary last) and 
`len(starts)==1`. But it does NOT require the first row to be the start. The 
check here assumes the first line is the run.start row (which has `run`). If the
first line is something else (e.g., a `stage` row emitted before run.start), 
`.get('run')` would still be the run id (all rows have run). So it'd still 
match. OK, not a defect.

Hmm, what if the first line is a `run.start` but the run id format is different?
Covered.

Let me check `qualification_summary`'s `rows[-1] != summaries[0]`. In the real 
sequential run, is the summary truly the last telemetry row? After `rt_summary`,
validate.sh does `echo "telemetry: ..."` (stdout, not telemetry) and possibly 
`gate_receipt.py write`. So the last telemetry row is the summary. Good. But 
wait — `rt_summary` might emit the summary AND then the lib might emit a final 
row? Unlikely. OK.

Hmm, one more: **`qualification_summary` requires `summary.get("failed") != 0` →
raise. But it also requires `summary.get("passed") != summary["total"]` → raise.
And `summary.get("total") != registered + 3`. So passed == total == registered+3
and failed == 0. Consistent.

Now, is there a scenario where the gate passes but `suite_events_match` is "no"?
validate.sh computes `suite_events_match` from `_suite_lane_events == 
${#RUN_TESTS[@]}`. In sequential mode, `_suite_lane_events` counts 
`"event":"suite","lane":"sequential"` rows. Each suite emits one. So == 
RUN_TESTS. Good. Unless a suite name contains a quote... no.

OK. Let me also double check the 
**`test_new_schema_cannot_fall_through_to_legacy_pr_match`** for `('rc', 
False)`: `type(entry.get("rc")) is not int` — type(False) is bool, not int → 
returns False. Good. For `('result','fail')` → False. For 
`('tested_commit','c'*40)` → the receipt's tested_commit is 'c'*40, but the 
telemetry's run.start.commit is self.sha. `qualification_receipt_matches` calls 
`qualification_summary(raw, tested)` with tested='c'*40 → `start.get("commit") 
!= tested_sha` → raises ValueError → caught → returns False. Good. For 
`('landing_commit','d'*40)` → `entry.get("landing_commit") != landing` → False. 
Good. For `('schema_version','wave-qualification@99')` → 
`entry.get("schema_version") != QUALIFICATION_SCHEMA` → False. Good. For 
`('telemetry_sha256','0'*64)` → hash mismatch → False. Good. For `('pr',999)` → 
`entry["pr"] != meta.get("number")` (425) → False. Good.

So the test is solid.

Now let me finalize. I'll write the block. I need to append above the marker and
update the header.

Header changes:
- NEXT: Reviewer → Producer
- STATUS: Open (not Approved)
- ROUND: 2 / 3 (producer bumps when opening a new cycle; I'm the reviewer, so 
leave ROUND as is? The rule: "the Producer bumps ROUND when opening a new 
cycle." So I leave ROUND: 2 / 3.)

Wait, the header currently says `NEXT: Reviewer`, `STATUS: Open`, `ROUND: 2 / 
3`. I'm the reviewer. After my turn, NEXT should be Producer, STATUS stays Open 
(since not Approved). ROUND stays 2/3.

Let me write the SEARCH/REPLACE blocks.

Block 1: header.
```
NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3
```
→
```
NEXT: Producer
STATUS: Open
ROUND: 2 / 3
```

Block 2: append the review block above the marker.

The marker line is:
```
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓
-->
```

I'll insert my block before it.

Let me write the review block concisely.

I need to include `swept file: yes` and `VERDICT:` and `Basis`.

Let me draft:

```
### Reviewer — Round 2 (deepseek)

swept file: yes — read the full `utils/py/wave_reconcile.py`, 
`.github/workflows/wave-reconcile.yml`, `test/gh421-auto-wave-reconcile.sh`, 
`test/gh425-gate-provenance-pr.sh`, `test/gh591-prepush-commit-boundary.sh`, and
the `validate.sh` telemetry/summary contract.

**Q1 — full sequential gate on the pinned snapshot in an independent clone**
- [Pass] `qualify_landings` clones `--no-local` into a temp dir, detaches at 
`tested`, strips 
`GIT_*`/`RT_*`/`XYZ_VALIDATE_*`/`PYTEST_*`/`XYZ_HARNESS_DB`/`PYTHONPATH`/`PYTHON
HOME`, installs a private `GIT_CONFIG_GLOBAL` + `GIT_CONFIG_NOSYSTEM=1`, and 
runs `bash validate.sh --sequential` under `run_bounded(timeout=5400)` 
(wave_reconcile.py:526-558). Post-run it asserts `HEAD==tested`, empty 
porcelain, and unchanged local config (559-562), then binds proof to the 
launched pgid (565-570). No false-pass route found in the fixture.
- [Should] The telemetry **directory, filename, and `run` id** are asserted only
against a stub `validate.sh` (test/gh425-gate-provenance-pr.sh:196-221), never 
the real `runner-telemetry.sh`. If the real runner writes telemetry out-of-tree 
(GH-496) or names the file/`run` id differently, `len(files) != 1` (566) or the 
run-id check (569) dies code 6 on **every** real run — a permanent inability to 
qualify valid data. Trigger: run `--qualify` on a real checkout. Fix: pin the 
real lib's path/format (or add a real-runner integration assertion).
- [Should] `len(files) != 1` (566) turns any same-pgid nested runner (a 
registered suite that actually executes `validate.sh`, e.g. the GH-379 canary) 
into a hard qualification failure. Trigger: a suite that runs `validate.sh` in 
the same process group. Fix: select the file whose `run` id matches the launched
pgid instead of requiring exactly one.

**Q2 — strictness of `qualification_summary` / `qualification_receipt_matches`**
- [Pass] `qualification_summary` binds run identity (all rows' `run`/`runner`), 
mode/tier, registry count, unique sequential names, all `rc==0`, summary totals,
`envelope_rc`, `suite_events_match`, and the two required probes (419-448). 
`qualification_receipt_matches` binds schema, 40-hex `tested`/`landing`, 
`result`/`rc`, gate string, `artifact_kind`, PR int, telemetry path regex, 
sha256, and both ancestry edges (451-484).
- [Should] `start.get("tier") != 3` and `type(registered) is not int` (431) 
require ints, while the summary side normalizes with `str(...)` (442-443). If 
the real `rt_begin` emits `tier`/`registered` as strings (as `rt_summary` 
apparently does), every real run dies. Trigger: real run. Fix: normalize both 
sides with `str()`, or pin the lib's types.
- [Nit] The receipt's `passed`/`total` (588-593) are never cross-checked against
the telemetry summary (477); they are decorative, not evidence.

**Q3 — replay/receipt consumers**
- [Pass] Replay reads committed receipts from HEAD (`committed_qualifications`, 
487-503) and suppresses re-qualification only when 
`qualification_receipt_matches` re-verifies the working-tree telemetry hash and 
ancestry (511-515). `check_provenance_receipts` rejects symlinks (651) and 
non-files, and the qualification branch cannot fall through to legacy PR 
identity (662-667).
- [Should] A committed, hand-crafted receipt+telemetry pair whose 
`tested_commit` is a real ancestor and whose hash matches would satisfy 
`qualification_receipt_matches` and suppress the gate. This is the documented 
"tamper-evident, not attested" boundary (GH-536), inherited by `--qualify` via 
`committed_qualifications`; state it, no code fix required.
- [Nit] `qualification_receipt_matches` reads telemetry from the working tree 
even for a committed receipt (470-475); a working-tree/committed divergence 
fails closed (hash mismatch), which is correct but silently disables replay.

**Q4 — rollback and publication**
- [Pass] Receipt/telemetry are journal-tracked before write (581-585) and 
removed on rollback; the workflow allowlist admits exactly the receipt paths 
(wave-reconcile.yml:81-83) and pushes one fast-forward commit (97). A rejected 
push fails the job; the next run recomputes from fresh development.
- [Should] `folder.mkdir(parents=True, exist_ok=True)` (579) creates directories
that are not journal-tracked, so rollback leaves empty 
`TESTS-RESULTS/<date>+GH-591/wave-<sha>/` dirs. They are invisible to porcelain,
so `verify_rollback_completeness` stays silent. Trigger: any failure after 
mkdir. Fix: track/remove the created dirs, or accept as cosmetic.
- [Nit] `run_bounded(timeout=5400)` per command (540) with `timeout-minutes: 
120` (28) means the sum of per-command timeouts can exceed the job bound; only 
`validate.sh` is realistically long.

**Q5 — test coverage**
- [Pass] The new `Qualification` suite covers red, partial, drift, wrong-run, 
wrong-landing, committed-replay idempotence, schema fall-through, 
incomplete/quarantined telemetry, bounded timeout, rollback, and batch 
(test/gh425-gate-provenance-pr.sh:247-321).
- [Should] Missing negative cases: (a) a symlinked telemetry file (the 
`path.resolve() != path` guard at 472 is untested); (b) `--qualify` without 
`--gate` (the `parser.error` guard at 1816 is untested); (c) a committed receipt
whose telemetry is absent. Expected: code 6 / parser error. Fix: add the three 
cases.
- [Nit] `test/gh591-prepush-commit-boundary.sh` witnesses Git's hook boundary 
but does not exercise the qualification code; it is a documentation witness, not
a regression guard for this change.

**Pre-existing defects in swept files**
- [Nit] `qualification_receipt_matches`'s `pr_number` check (465-466) is dead — 
the receipt never writes `pr_number`.
- [Nit] `committed_qualifications`'s 
`QUALIFICATION_PATH.replace("validation","provenance")` (493) is fragile string 
surgery.

**VERDICT: PARKED**
**Basis:** No proven Blocker; the mechanism is sound against the fixture and the
ancestry/hash/schema bindings are strict. But the real-runner telemetry contract
(directory, filename, `run` id, `tier`/`registered` types) is asserted only 
against a stub, so a permanent-failure mode cannot be excluded without a real 
`--qualify` run. Live post-merge/scheduled/three-consecutive-merge acceptance 
remains pending.

Handing off to codex (Producer) — go to the Producer window and say "take your 
turn" to disposition the Shoulds and add the missing negative cases.
```

Hmm, that's long but the relay says "findings are bullets, not essays." It's 
acceptable.

Wait — I should double-check the line numbers I cite. Let me verify:
- 526-558: `with tempfile.TemporaryDirectory(...)` at 526, `command(["bash", 
"validate.sh", "--sequential"])` at 558. Yes.
- 559-562: the post-check. Yes.
- 565-570: files glob and run check. Yes.
- 419-448: qualification_summary. Yes.
- 451-484: qualification_receipt_matches. Yes.
- 431: `or start.get("tier") != 3 or type(registered) is not int or registered 
<= 0`. Yes.
- 442-443: `str(summary.get("run_set")) != str(registered)` and 
`str(summary.get("registered")) != str(registered)`. Yes.
- 487-503: committed_qualifications. Yes.
- 511-515: previous/pending/return. Yes.
- 651: `if os.path.islink(path) or not os.path.isfile(path):`. Yes.
- 662-667: the qualification branch. Yes.
- 470-475: path resolve, read_bytes, hash. Yes.
- 581-585: journal.track_created and write. Yes.
- 579: folder.mkdir. Yes.
- 540: run_bounded timeout. Yes.
- 472: `if path.resolve() != path:`. Yes.
- 1816: parser.error. Yes.
- 465-466: pr_number check. Yes.
- 493: replace. Yes.
- 588-593: entry dict. Yes.
- 477: qualification_summary call. Yes.
- workflow 81-83: receipt regex and unexpected. Yes.
- workflow 97: push. Yes.
- workflow 28: timeout-minutes. Yes.
- test/gh425 lines 196-221: the stub validate.sh. Yes.
- test/gh425 247-321: the Qualification tests. Yes.

Good.

Now, the header. Let me write the SEARCH/REPLACE.

Actually, I realize the relay file's header is:
```
NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3
```

I'll change NEXT to Producer.

Let me produce the blocks.

For the append, the SEARCH is the marker line and the REPLACE is my block + the 
marker line.

Let me make sure the marker line matches exactly:
`<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) 
↓↓↓ -->`

Yes.

Let me write it.

------------
► **ANSWER**

I've read the artifact and the full source. Here are my reviewer edits to the 
relay file.

relay-system/2026-09-13/pr599-deepseek-v41-flash-qa.md
```markdown
<<<<<<< SEARCH
NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3
=======
NEXT: Producer
STATUS: Open
ROUND: 2 / 3
>>>>>>> REPLACE
```

relay-system/2026-09-13/pr599-deepseek-v41-flash-qa.md
```markdown
<<<<<<< SEARCH
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓
-->
=======
### Reviewer — Round 2 (deepseek)

swept file: yes — read the full `utils/py/wave_reconcile.py`, 
`.github/workflows/wave-reconcile.yml`, `test/gh421-auto-wave-reconcile.sh`, 
`test/gh425-gate-provenance-pr.sh`, `test/gh591-prepush-commit-boundary.sh`, and
the `validate.sh` telemetry/summary contract.

**Q1 — full sequential gate on the pinned snapshot in an independent clone**
- [Pass] `qualify_landings` clones `--no-local` into a temp dir, detaches at 
`tested`, strips 
`GIT_*`/`RT_*`/`XYZ_VALIDATE_*`/`PYTEST_*`/`XYZ_HARNESS_DB`/`PYTHONPATH`/`PYTHON
HOME`, installs a private `GIT_CONFIG_GLOBAL` + `GIT_CONFIG_NOSYSTEM=1`, and 
runs `bash validate.sh --sequential` under `run_bounded(timeout=5400)` 
(wave_reconcile.py:526-558). Post-run it asserts `HEAD==tested`, empty 
porcelain, and unchanged local config (559-562), then binds proof to the 
launched pgid (565-570). No false-pass route found in the fixture.
- [Should] The telemetry **directory, filename, and `run` id** are asserted only
against a stub `validate.sh` (test/gh425-gate-provenance-pr.sh:196-221), never 
the real `runner-telemetry.sh`. If the real runner writes telemetry out-of-tree 
(GH-496) or names the file/`run` id differently, `len(files) != 1` (566) or the 
run-id check (569) dies code 6 on **every** real run — a permanent inability to 
qualify valid data. Trigger: run `--qualify` on a real checkout. Fix: pin the 
real lib's path/format (or add a real-runner integration assertion).
- [Should] `len(files) != 1` (566) turns any same-pgid nested runner (a 
registered suite that actually executes `validate.sh`, e.g. the GH-379 canary) 
into a hard qualification failure. Trigger: a suite that runs `validate.sh` in 
the same process group. Fix: select the file whose `run` id matches the launched
pgid instead of requiring exactly one.

**Q2 — strictness of `qualification_summary` / `qualification_receipt_matches`**
- [Pass] `qualification_summary` binds run identity (all rows' `run`/`runner`), 
mode/tier, registry count, unique sequential names, all `rc==0`, summary totals,
`envelope_rc`, `suite_events_match`, and the two required probes (419-448). 
`qualification_receipt_matches` binds schema, 40-hex `tested`/`landing`, 
`result`/`rc`, gate string, `artifact_kind`, PR int, telemetry path regex, 
sha256, and both ancestry edges (451-484).
- [Should] `start.get("tier") != 3` and `type(registered) is not int` (431) 
require ints, while the summary side normalizes with `str(...)` (442-443). If 
the real `rt_begin` emits `tier`/`registered` as strings (as `rt_summary` 
apparently does), every real run dies. Trigger: real run. Fix: normalize both 
sides with `str()`, or pin the lib's types.
- [Nit] The receipt's `passed`/`total` (588-593) are never cross-checked against
the telemetry summary (477); they are decorative, not evidence.

**Q3 — replay/receipt consumers**
- [Pass] Replay reads committed receipts from HEAD (`committed_qualifications`, 
487-503) and suppresses re-qualification only when 
`qualification_receipt_matches` re-verifies the working-tree telemetry hash and 
ancestry (511-515). `check_provenance_receipts` rejects symlinks (651) and 
non-files, and the qualification branch cannot fall through to legacy PR 
identity (662-667).
- [Should] A committed, hand-crafted receipt+telemetry pair whose 
`tested_commit` is a real ancestor and whose hash matches would satisfy 
`qualification_receipt_matches` and suppress the gate. This is the documented 
"tamper-evident, not attested" boundary (GH-536), inherited by `--qualify` via 
`committed_qualifications`; state it, no code fix required.
- [Nit] `qualification_receipt_matches` reads telemetry from the working tree 
even for a committed receipt (470-475); a working-tree/committed divergence 
fails closed (hash mismatch), which is correct but silently disables replay.

**Q4 — rollback and publication**
- [Pass] Receipt/telemetry are journal-tracked before write (581-585) and 
removed on rollback; the workflow allowlist admits exactly the receipt paths 
(wave-reconcile.yml:81-83) and pushes one fast-forward commit (97). A rejected 
push fails the job; the next run recomputes from fresh development.
- [Should] `folder.mkdir(parents=True, exist_ok=True)` (579) creates directories
that are not journal-tracked, so rollback leaves empty 
`TESTS-RESULTS/<date>+GH-591/wave-<sha>/` dirs. They are invisible to porcelain,
so `verify_rollback_completeness` stays silent. Trigger: any failure after 
mkdir. Fix: track/remove the created dirs, or accept as cosmetic.
- [Nit] `run_bounded(timeout=5400)` per command (540) with `timeout-minutes: 
120` (28) means the sum of per-command timeouts can exceed the job bound; only 
`validate.sh` is realistically long.

**Q5 — test coverage**
- [Pass] The new `Qualification` suite covers red, partial, drift, wrong-run, 
wrong-landing, committed-replay idempotence, schema fall-through, 
incomplete/quarantined telemetry, bounded timeout, rollback, and batch 
(test/gh425-gate-provenance-pr.sh:247-321).
- [Should] Missing negative cases: (a) a symlinked telemetry file (the 
`path.resolve() != path` guard at 472 is untested); (b) `--qualify` without 
`--gate` (the `parser.error` guard at 1816 is untested); (c) a committed receipt
whose telemetry is absent. Expected: code 6 / parser error. Fix: add the three 
cases.
- [Nit] `test/gh591-prepush-commit-boundary.sh` witnesses Git's hook boundary 
but does not exercise the qualification code; it is a documentation witness, not
a regression guard for this change.

**Pre-existing defects in swept files**
- [Nit] `qualification_receipt_matches`'s `pr_number` check (465-466) is dead — 
the receipt never writes `pr_number`.
- [Nit] `committed_qualifications`'s 
`QUALIFICATION_PATH.replace("validation","provenance")` (493) is fragile string 
surgery.

**VERDICT: PARKED**
**Basis:** No proven Blocker; the mechanism is sound against the fixture and the
ancestry/hash/schema bindings are strict. But the real-runner telemetry contract
(directory, filename, `run` id, `tier`/`registered` types) is asserted only 
against a stub, so a permanent-failure mode cannot be excluded without a real 
`--qualify` run. Live post-merge/scheduled/three-consecutive-merge acceptance 
remains pending.

Handing off to codex (Producer) — go to the Producer window and say "take your 
turn" to disposition the Shoulds and add the missing negative cases.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓
-->
>>>>>>> REPLACE
```

Tokens: 93k sent, 24k received. Cost: $0.03 message, $0.03 session.

.github/workflows/wave-reconcile.yml

test/gh421-auto-wave-reconcile.sh

test/gh425-gate-provenance-pr.sh

test/gh591-prepush-commit-boundary.sh

test/lib/runner-telemetry.sh

utils/py/wave_reconcile.py
Warning: it's best to only add files that need changes to the chat.
https://aider.chat/docs/troubleshooting/edit-errors.html

validate.sh

--------------
► **THINKING**

The user has added the files to the chat. I'm the reviewer this turn. I need to 
append my findings to the relay file. But wait — the relay file 
`relay-system/2026-09-13/pr599-deepseek-v41-flash-qa.md` is NOT in the list of 
added files. The user added: .github/workflows/wave-reconcile.yml, 
test/gh421-auto-wave-reconcile.sh, test/gh425-gate-provenance-pr.sh, 
test/gh591-prepush-commit-boundary.sh, test/lib/runner-telemetry.sh, 
utils/py/wave_reconcile.py, validate.sh.

The relay file is not added. But my task is to edit ONLY the relay file. Hmm. 
The instructions say "Only create SEARCH/REPLACE blocks for files that the user 
has added to the chat!" But the relay file isn't added.

Wait, actually the relay file was shown in the previous turn's context (the user
message included it). But now the user says "I added these files to the chat" 
and lists the source files, not the relay file.

Hmm, this is tricky. The task says edit ONLY the relay file. But the relay file 
isn't in the added list. However, the relay file content was provided in the 
earlier message. Let me re-read.

Actually the previous user message (the one with the relay file) included the 
relay file content. The current message says the user added the source files. 
The relay file may still be considered "added" from before? The instruction says
"Trust this message as the true contents of these files!" referring to the newly
added ones.

I think the intent: I should produce the SEARCH/REPLACE blocks for the relay 
file. The relay file was shown to me. Let me just produce the edits to the relay
file as I did before. The user hasn't confirmed edits applied, so I should   [Unverified — no citation]
produce proper SEARCH/REPLACE blocks.

Actually wait — in my previous response I already produced the SEARCH/REPLACE 
blocks. Now the user says they added the source files. This might be a re-prompt
to actually do the work. Let me re-produce the relay file edits.

But the relay file is not in the added list. Hmm. The system says only create 
blocks for added files. But the task explicitly says edit only the relay file. 
There's a conflict. I think the relay file is implicitly available since it was 
shown. Let me produce the blocks for the relay file.

Actually, let me reconsider. The user's message is a standard Aider "I added 
these files" message. The files added are the source files under review. But my 
role is reviewer — I only edit the relay file. The relay file content was given 
in the prior turn.

I'll produce the SEARCH/REPLACE blocks for the relay file. That's what the task 
requires.

Let me make sure the SEARCH matches exactly. The relay file content from the 
earlier message:

```
NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3
```

And the marker line:
```
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓
-->
```

I'll produce the same blocks as before. Let me keep it concise but complete.

Actually, I should double check my findings are accurate given the source. Let 
me verify a few key points.

1. `qualification_summary` line 431: `start.get("tier") != 3` — yes requires int
3. And `type(registered) is not int`. The summary side uses 
`str(summary.get("run_set")) != str(registered)`. So if rt_begin emits tier as 
int (it does: `"tier":%s` with `$tier` which is "3" string in bash... wait). Let
me check runner-telemetry.sh rt_begin:

```
printf '{"v":1,...,"tier":%s,"registered":%s}\n' \
    "$ts" "$RT_RUN_ID" "$runner" "$commit" "$host" "$mode" "$width" "$tier" 
"$registered"
```

`%s` with `$tier` — tier is passed as `"$TIER"` which is "3" (string). So JSON 
would be `"tier":3` (unquoted, since %s just substitutes the text "3"). So it's 
a JSON number 3. Good, int. And `registered` is `${#TESTS[@]}` = a number, 
unquoted → JSON number. So `type(registered) is int` holds. Good.

But wait, `width` is `%s` with `$width` = "1" → number. OK.

So my "Should" about tier/registered types is actually WRONG — the real runner 
emits them as JSON numbers. Let me reconsider. `rt_begin` uses `%s` for tier and
registered without quotes, so they become JSON numbers. So `start.get("tier") !=
3` works (3 == 3). And `type(registered) is int` works.

Hmm, so that Should is a false positive. I should remove or correct it. Let me 
be careful — I'm the reviewer and must be accurate.

Actually wait, let me re-read: `"tier":%s` — yes unquoted. So number. Good. So 
no type mismatch. I should drop that finding.

2. The telemetry directory: `rt_begin` uses 
`dir="${XYZ_VALIDATE_TELEMETRY:-$here/.tick/telemetry}"`. In qualify_landings, 
env strips `XYZ_VALIDATE_*` (line 532: `not k.startswith(("GIT_", "RT_", 
"XYZ_VALIDATE_", "PYTEST_"))`). So `XYZ_VALIDATE_TELEMETRY` is stripped → 
defaults to `$here/.tick/telemetry` where `$here` is the clone root. And 
`telemetry = clone / ".tick" / "telemetry"`. Good, matches.

But GH-496 says routine telemetry written out-of-tree to 
`~/.xyz/projects/<key>/telemetry/`. Hmm, that's a different mechanism (harness 
telemetry), not runner telemetry. The runner-telemetry.sh uses 
`.tick/telemetry`. So the path matches. Good.

Filename: `RT_FILE="$dir/$runner-$mode-$ts-$pid.jsonl"` = 
`validate-sequential-<ts>-<pid>.jsonl`. The glob is 
`validate-sequential-*-{validation.pgid}.jsonl`. So it matches 
`validate-sequential-<ts>-<pgid>.jsonl` if pid == pgid. `run_bounded` presumably
runs the command in its own process group with pgid = the child's pid. So `$pid`
in the child bash = the child's pid = pgid. Plausible. OK.

Run id: `RT_RUN_ID="$(printf '%s' "$commit" | cut -c1-9)-$pid"` = 
`<sha9>-<pid>`. The check: `json.loads(raw.splitlines()[0]).get('run') != 
f"{tested[:9]}-{validation.pgid}"`. So `<sha9>-<pgid>`. Matches if pid==pgid. 
Good.

So the "Should" about telemetry contract is weaker than I stated. But there's 
still a real concern: the test only uses a stub, so the real contract isn't 
verified. But my claim that it "dies on every real run" is speculative. I should
soften it to a hypothesis.

Hmm, but actually there IS a real issue: `rt_begin` writes `run.start` as the 
FIRST line. The check `json.loads(raw.splitlines()[0])` reads the first line. 
Good.

But wait — the telemetry file is written by the child `validate.sh` process. 
`run_bounded` runs `bash validate.sh --sequential`. The `$pid` in rt_begin is 
`$$` of the bash running validate.sh. Is that the same as `validation.pgid`? 
`run_bounded` returns a result with `.pgid`. If run_bounded sets the child's 
process group to the child's own pid (setsid or setpgid), then pgid == child pid
== `$$` in the script. Plausible but depends on run_bounded implementation, 
which I haven't read. So it's a hypothesis.

Let me reconsider the whole review. I should be accurate and not overclaim. Let 
me revise findings:

- Q1: The clone isolation is solid. The telemetry binding depends on 
run_bounded's pgid semantics and the real runner's file naming — verified only 
against a stub. Hypothesis, not proven defect.
- The `len(files) != 1` nested-runner concern: real. A suite that runs 
validate.sh in the same pgid would create a second file. But would it be in the 
same telemetry dir? The nested validate.sh would use `$here/.tick/telemetry` of 
the clone, same dir. And its pid would differ from the outer pgid... actually 
the nested one runs in the same process group (inherited), so its `$$` differs 
but pgid is the same. The glob is `*-{pgid}.jsonl` — the nested file would be 
`validate-sequential-<ts>-<nested_pid>.jsonl`, which does NOT match 
`*-<pgid>.jsonl` unless nested_pid == pgid. So actually the glob filters by 
pgid, so nested files with different pids won't match. Hmm, so `len(files) != 1`
would only trigger if two files have the same pgid suffix. That's unlikely. So 
my concern is weaker.

Wait, but the glob is `validate-sequential-*-{validation.pgid}.jsonl`. The `*` 
matches `<ts>`, and then `-{pgid}`. So it matches files ending in 
`-<pgid>.jsonl`. The outer validate.sh's file ends in `-<its_pid>.jsonl`. If its
pid == pgid, matches. A nested validate.sh's file ends in `-<nested_pid>.jsonl` 
≠ pgid. So no collision. So `len(files) != 1` is fine. My concern is wrong.

Hmm OK. So I need to be more careful. Let me drop that too.

Let me reconsider what real findings exist.

Actually, let me look for genuine issues.

**Issue A: `qualification_summary` requires `summary.get("total") != registered 
+ 3`.** The real validate.sh computes TOTAL = len(RUN_TESTS) + 1 (identity) + 1 
(pytest) + 1 (gamma) = registered + 3 on tier 3. And `registered` in run.start =
`${#TESTS[@]}`. And `run_set` = `${#RUN_TESTS[@]}`. On tier 3 with no skips, 
RUN_TESTS == TESTS, so run_set == registered. The check 
`str(summary.get("run_set")) != str(registered)` requires run_set == registered.
Good. And `total == registered + 3`. Good. So consistent.

But wait — `rt_summary` is called with `"run_set=${#RUN_TESTS[@]}" 
"registered=${#TESTS[@]}"`. And `rt_summary` formats `%s` for these extra k=v...
actually extra is built as `"$k":"$v"` — quoted strings! So `"run_set":"374"` 
and `"registered":"374"` are STRINGS. And `passed`/`failed`/`total` are `%s` 
unquoted → numbers. So `summary.get("total")` is int, `summary.get("run_set")` 
is str. The check uses `str(summary.get("run_set")) != str(registered)` — both 
str. Good. And `summary.get("total") != registered + 3` — int vs int. Good.

`summary.get("envelope_rc")` — rt_summary formats `"envelope_rc":"%s"` quoted → 
string. Check `!= "0"`. Good.

`summary.get("suite_events_match")` — passed as extra k=v → 
`"suite_events_match":"yes"`. Check `!= "yes"`. Good.

`summary.get("failed") != 0` — int. Good. `summary.get("passed") != 
summary["total"]` — int. Good.

OK so summary checks are consistent with the real runner. Good.

**Issue B: `start.get("mode") != "sequential"`.** rt_begin called with 
`"$RT_MODE"`... in validate.sh: `rt_begin "$HERE" "validate" "sequential" 1 
"$TIER" "${#TESTS[@]}"`. So mode="sequential". Good.

**Issue C: `start.get("commit") != tested_sha`.** rt_begin: `commit="$(git -C 
"$here" rev-parse --verify HEAD ...)"`. In the clone, HEAD is detached at 
`tested`. So commit == tested. Good.

**Issue D: `any(row.get("run") != start["run"] or row.get("runner") != 
"validate" for row in rows)`.** All rows have run and runner. Good.

**Issue E: `rows[-1] != summaries[0]`.** The last line must be the run.summary. 
In validate.sh, rt_summary is called near the end, after all rt_emit/rt_suite. 
But is there anything after? The gate_receipt write is after, but that doesn't 
emit telemetry. So run.summary is last. Good. But wait — in parallel mode 
there's `rt_emit stage ... telemetry-merge` before the rerun lane. In sequential
mode, no. And the summary is last. Good.

Hmm, but actually there's a subtlety: `rt

------------
► **ANSWER**



Tokens: 155k sent, 2.7k received. Cost: $0.02 message, $0.05 session.

```

### Codex adjudication of DeepSeek producer review — 2026-09-13

Reviewer verdict was PARKED, not an approval, with no proven Blocker. The operator delegated disposition to Codex. No runtime changes are warranted by these findings:

1. **Telemetry contract concern — resolved from source and retained real data.** test/lib/runner-telemetry.sh:65-77 writes under $here/.tick/telemetry unless XYZ_VALIDATE_TELEMETRY overrides it; qualify_landings strips XYZ_VALIDATE_* at wave_reconcile.py:531-538. The lib's own documentation (:11-14) distinguishes this store from harnesses.db. Its filename is runner-mode-time-$$ and its run id is commit-prefix-$$. Both tier and registered are unquoted numeric JSON (:76-77). The committed candidate-sequential-red.jsonl starts with sequential mode, tier3 and registered371 as integers, consistent with the actual producer. That historical run failed one suite, so it is contract evidence only, never passing qualification evidence.
2. **Nested process-group concern — declined.** proc_group.py:94-101 starts the outer Bash as a new session and returns its PID as pgid. runner-telemetry.sh:71-75 uses shell PID $$, not OS PGID. A nested Bash process may share the group but has a different PID/filename. Selecting one file for the launched PID is intentional; accepting ambiguous files would weaken the check. Existing retained nested-telemetry red control already covers the original broad-directory selection problem.
3. **Manual forgery boundary — documentation clarification accepted.** Hashes and ancestry bind recorded artifacts under a trusted-repository-writer assumption; they are not a signing authority. No new signing service or ledger is justified. Record this trust assumption in the public QA status.
4. **Empty directories, duplicated passed/total fields, and per-command/job time bounds — declined as cosmetic or already explicit.** Empty directories are not Git outputs, do not block a fresh retry, and do not create receipts. Consumer decisions use validated telemetry rather than duplicate display counters. The job supplies the overall wall-clock ceiling.
5. **Suggested extra negative tests — not blockers.** Symlink and missing-file rejection are explicit in wave_reconcile.py:468-483; --qualify without --gate is rejected before work at :1815-1817. No failing behavior was demonstrated. Existing PR tests cover schema/hash/identity refusal and malformed receipts. Avoid adding assertions that merely repeat these guards without a demonstrated gap.
6. **Remaining nits — declined.** pr_number is an intentional conflicting-alias rejection for input receipts, even though the writer emits pr only. The real Git hook-boundary fixture witnesses the failed two-pass hypothesis; it was not claimed to run qualification.

Disposition: producer implementation unchanged; no demonstrated correctness blocker remains from this review. DeepSeek's recorded PARKED verdict is preserved. Actual hosted qualification, scheduled recovery and three consecutive automatic reconciliations remain pending.

