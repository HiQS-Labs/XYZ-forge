I have what I need; writing up now.

**ANSWER**

The plan is directionally right but two things round one flagged are still unfixed in this refinement, and one codification point was missed entirely: the marathon reviewer brief at `utils/py/marathon_drive.py:2951-2957` already tells reviewers to verify with probe files under `$TMPDIR`, so the "reviewer cannot measure" diagnosis is only true for `/relay` threads, and S2's generalization rule never reaches marathon relays at all. Proceed after fixing the prompt contradiction, aligning the scratch location with GH-441, and stating the marathon scope explicitly.

**FINDINGS**

- **[Blocker] The rendered reviewer prompt will contradict itself.** `relay-turn-lib.sh:1055` appends, after the role note, "verify ONLY with the specific test for the file(s) you changed". S1 then says "Do NOT run `test/*.sh`". Both land in one reviewer prompt, which is the GH-397 failure class (`:1034-1036`). Codex flagged this in round one (`gh681-plan-qa.codex.md:4173`) and no S-item touches it. Fix: add one clause to S1 ("the 'specific test' instruction below is for Producer turns; as Reviewer, run probes only") or make that sentence role-conditional in the same printf.

- **[Should] S1's recipe still disagrees with the marathon brief and the agy shim.** `marathon_drive.py:2951-2957` says probe files go under `$TMPDIR`, "never inside the working tree"; `agy-turn.py:386-390` says "$TMPDIR or .relay-scratch/"; S1 says `.relay-scratch/` only. Three sanctioned locations in one context window. Fix: S1 wording "under `$TMPDIR` or `.relay-scratch/`" so all three agree. Also `TMPDIR=.relay-scratch/tmp` is relative; use `$PWD/.relay-scratch/tmp`.

- **[Should] S2 does not reach marathon relays.** `marathon_drive.py:2943-2960` and `marathon-drive.sh:1067-1074` render their own reviewer TAKE YOUR TURN block; they never go through `new-relay.sh`. The plan's blast-radius section says S2 "changes only newly scaffolded relay files", which silently excludes the lane where most headless reviewer turns run. `marathon_drive.py` is not in `FROZEN_TWINS` (`express.py:40-53`), so a one-line 4c is cheap. Otherwise state the exclusion and file the follow-up.

- **[Should] `python3 -B` is not enough, and the plan already heard this.** Codex's Q3 (`codex.md:4165`) showed `-B` does not propagate to child interpreters, and `_rtl_sig` hashes every file under `.relay-artifacts/` regardless of gitignore (`:715`, `:909-913`). S1 still says `python3 -B`. Fix: the recipe should be `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`. That is prose, not a shim change, so the deferral stands.

- **[Should] pytest residue path is open.** `.pytest_cache/` and `.hypothesis/` are dot-directories, not gitignored (`.gitignore:36` covers only `__pycache__/`), refused by `rtl_scratch_relocate` (`:1128`), so a "narrow probe" like `python3 -m pytest test/test_python_layer.py -k x` (the repo's own pytest file, `validate.sh:1394`) ends the turn at exit 6 (`:924`). S1 bans `test/*.sh` but never mentions pytest. Fix: either name `-p no:cacheprovider` in S1 or add `.pytest_cache/` to `.gitignore` (no logic, invisible to porcelain, harmless in a throwaway worktree).

- **[Should] Lane steps 2 and 3 still violate the rules they cite.** Step 2 runs express "first" but `express.py:438-440` refuses `empty` before any surface check, and `refuse()` exits on the first hit, so the receipt cannot show both `shared-runtime` and `no-new-bash`. Step 3 runs the suite and the GH-308 guard in the task clone, which `AGENTS.md:15` forbids. Both were in Codex's list (`codex.md:4177`, `:4179`). Fix: express after implementation, expect one refusal; run every suite in the disposable clone.

- **[Should] "Never modify a tracked file" forbids the relay file.** The relay file is tracked and is the one thing the reviewer must modify. Codex's Q5 raised it; S1 still carries the sentence. Fix: "Never modify a tracked file other than the relay file".

- **[Nit] S5 case 6 cites the wrong model.** `test/gh660-skill-drift.sh` tests `skill_drift_check` on fixtures; the phrase-grep-plus-mutation model S5 wants is `test/gh617-relay-xyz-commensurate-review.sh:20-50`, which also proves S3's insert into `:604-609` is safe (greps phrases, not numbering).

- **[Nit] The "consult Blocker, now mechanical" red control is already mechanical.** `test/gh505-relay-attest.sh:366` asserts "set STATUS: Approved" in the reviewer prompt today. Not wrong, just not new.

- **[Pass] One edit point for the prompt string.** `utils/py/rtl.py:792-795` shells out to `rtl_turn_prompt`; `claude-turn.sh:233` and `claude-turn.py:204` give reviewers Bash, so the allowance is real on every lane except Aider, which is structurally read-only (`aider-turn.sh:149-178`) and unharmed.

- **[Pass] Scratch is exempt end to end.** `.relay-scratch/` is pre-created (`:826`), exempt in `rtl_worktree_end` (`:898`), and gitignored (`.gitignore:102`).

**RECOMMENDATION**

Proceed once S1 is reconciled with `:1055` and GH-441, the marathon lane is either covered or explicitly excluded, and the recipe uses the exported env vars Codex already asked for.

```
Q1: Right cut for the motivating case: the gh673 measurement is a read-only sqlite query plus a `python3 -c` import, both allowed. The forbidden measurement that matters is running the Producer's cited regression test (`bash test/gh<N>-*.sh`) to falsify an "Implemented" claim; AGENTS.md:15 forbids it in a linked worktree, and `relay-turn-lib.sh:1055` simultaneously tells the same reviewer to "verify ONLY with the specific test". Tell reviewers to cite the harness gate result instead, and remove the contradiction.
Q2: No. `new-relay.sh:136` ships the DoD as a placeholder, so "beyond the DoD" is undefined whenever it is left blank, and `:81-85` orders reviewers to sweep pre-existing code, which is always "beyond the cited reproduction". Sharper test: a finding is a generalization if the reviewer cannot paste the concrete input (row, value, `file:line`) that fails under current code. Make `Observed input:` mandatory for any [Blocker]/[Should] requesting a behaviour change; a mechanical version is one token in the awk claim trigger at `relay-turn-lib.sh:1228`, otherwise say plainly that S2 is prose only.
Q3: Not safe as written. `python3 -B` does not reach child interpreters (Codex, `codex.md:4165`), `_rtl_sig` hashes `.relay-artifacts/` including ignored bytecode (`:715`, `:909`), and `.pytest_cache/`/`.hypothesis/` are un-ignored dot-dirs that `rtl_scratch_relocate` refuses (`:1128`) so they end the turn at `:924`. Prose can close this: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"` plus `-p no:cacheprovider` or a `.pytest_cache/` gitignore line. The shim deferral itself is fine.
Q4: Wording only. Mutant: change S2's "MUST carry three lines" to "should" (or move the block into an HTML comment in the scaffold). S5 case 4 greps `Observed input:`/`Affected scope:`/`Falsifier:`/`Declined — unproven generalization` in `--print` output and stays green; the rule is now optional and the gh673 pattern recurs. Nothing in S5 feeds a relay through `rtl_enforce`, so no relay-content mutant can ever fail it.
Q5: `skills/relay/SKILL.md:249` says "Do not edit the artifact" and nothing about running; no contradiction. `AGENTS.md:15` agrees with S1's test ban. `AGENTS.md:222` routes scratch to `temp/`, but `.relay-scratch/` is the harness's own sanctioned exception (`:820-826`, `.gitignore:102`); S4 should say so. The live contradiction is inside the harness: `relay-turn-lib.sh:1055` vs S1, and `marathon_drive.py:2951` ("$TMPDIR, never inside the working tree") vs S1's `.relay-scratch/`.
NEW DEFECTS (things the plan does not know about; each with file:line and a fix):
- `utils/py/marathon_drive.py:2951-2957`: the marathon reviewer brief ALREADY permits probing under `$TMPDIR` (GH-441). The recon's "exactly one edit point, no twin" holds for the prompt string but not for the policy; the diagnosis "the reviewer cannot measure" is false for marathon lanes. Fix: S1 says "under `$TMPDIR` or `.relay-scratch/`"; add the marathon brief to the recon table.
- `utils/py/marathon_drive.py:2943-2960` / `relay-automation/marathon-drive.sh:1067-1074`: marathon relays never see S2. Fix: one-line 4c in the Python brief (not a frozen twin per `express.py:40-53`), or an explicit exclusion plus follow-up issue.
- `.gitignore:36` vs `relay-turn-lib.sh:1128`: `.pytest_cache/` is un-ignored and un-relocatable; S1 forbids `test/*.sh` but not pytest. Fix: `-p no:cacheprovider` in S1 or a `.pytest_cache/` gitignore line.
- S1 recipe `TMPDIR=.relay-scratch/tmp` is relative; breaks the moment a probe `cd`s. Fix: `$PWD/.relay-scratch/tmp`, exported.
- Plan §3 still carries `python3 -B`, "Never modify a tracked file", express-first (§5 step 2), and task-clone suite runs (§5 step 3) after Codex flagged each (`codex.md:4165`, `:4169`, `:4177`, `:4179`). Fix: apply them or record why the adjudication declined them.
VERDICT: PROCEED-WITH-CHANGES
Changes required before proceeding (if any):
- Reconcile S1 with `relay-turn-lib.sh:1055` so the reviewer prompt has one verification instruction.
- S1 recipe: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`, "$TMPDIR or .relay-scratch/", "tracked file other than the relay file", pytest cache handling.
- State S2's marathon coverage: add a 4c line to `marathon_drive.py:2951` or exclude it explicitly with an issue.
- Lane: express receipt after implementation expecting one refusal; all suites and red controls in the disposable clone.
- S5: add one behavioural case (reviewer worktree begin, write `.relay-scratch/probe.txt` and `.pytest_cache/x`, assert OFFLANE 0 and 1) or say the suite pins wording only.
One thing the other advisor will probably get wrong: accepting the recon claim that `:1042` is the only place a reviewer is told whether it may execute, and so missing that `marathon_drive.py:2951` already grants probing and names a different scratch location than S1.
```
