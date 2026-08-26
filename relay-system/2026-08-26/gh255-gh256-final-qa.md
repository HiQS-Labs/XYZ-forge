---
Goal: Final QA of the GH-255 + GH-256 change set
Date: 2026-08-26
NEXT: Reviewer
STATUS: Open
---

# Context

Adjudicate two commits on `development` as a single body of work. Review only — do not edit any
file except this relay thread.

- `9e99c85c` fix(GH-255): order the blocked-before-dispatch remedies by what is actually blocked
- `74bb8d1c` fix(GH-256): under --target-root, guard the repo the worktree is cut from

Read the full diff of both (`git show 9e99c85c`, `git show 74bb8d1c`) and the current state of:
- `utils/py/marathon_drive.py` — `preflight_write_set_trackable` and its two call sites (~2412-2420)
- `relay-automation/marathon-drive.sh` — the new `TARGET_ROOT` export block
- `relay-automation/relay-turn-lib.sh` — `rtl_worktree_begin`'s seed loop (~line 718)
- `test/gh255-remedy-ordering.sh`, `test/gh256-target-root-guard-root.sh`

REVIEW THE WHOLE FILE, NOT JUST THE DIFF. Pre-existing defects in the files these changes touch
are IN SCOPE; say so explicitly if you find none. Your review MUST contain a literal
`swept file: yes` or `swept file: no` line.

Background: both bugs were found by a real marathon that failed three times and wrote no code.
Both plans were QA'd by agy first, and agy falsified the GH-256 diagnosis outright — the fix
shipped is not the one originally planned.

Questions:

1. **GH-255 correctness.** `only_transcripts` is computed as
   `bool(_transcripts) and all(p in _transcripts for p, _ in blocked)`. Is the membership test
   sound given `blocked` holds `(path, rule)` tuples built from the same `paths` list? Any path
   normalization mismatch (symlinks, trailing slashes, relative vs absolute) that could make a
   transcript fail the `in` test and silently take the wrong branch?

2. **GH-255 call sites.** On the `commit_root != root` path the two calls are sequential and the
   first exits on failure. The commit claims per-call knowledge is sufficient there. Is that
   right, or is there a case where the phase-set call fires with transcripts also blocked and
   produces the wrong remedy?

3. **GH-256 blast radius.** `marathon-drive.sh` now exports `AGY_TURN_ROOT`, `CODEX_TURN_ROOT` and
   `COMMANDCODE_TURN_ROOT` when `--target-root` is set. Does anything else read those vars and
   change behaviour in a way this breaks — tests that point them at fixtures, or a same-repo path
   that could inherit them from a parent process?

4. **GH-256 completeness.** Are those three the complete set of shim guard-root vars? Is there a
   fourth shim (claude, aider, deepseek, ox-alpha) with the same pattern that was missed?

5. **The new stderr warning.** `rtl_worktree_begin` now warns on every unseeded artifact. A
   create-new-file phase hits this legitimately every run. Is this going to be noise that trains
   operators to ignore it, and if so what would be better?

6. **Test quality.** Both tests read source text rather than driving a live run. Is that
   defensible here, or does it make them assertions about wording that will pass while the
   behaviour regresses?

7. **What is missing?** Anything either commit should have covered and did not — docs that go
   stale, a migration concern, or an interaction between the two changes.

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite
file:line. Do not soften a real objection.

Write your verdict below. Set `STATUS: Approved` if the work is sound, or leave it Open with
`**Verdict:** Changes requested`.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex review — 2026-08-26

**Grade:** F

**Verdict:** Changes requested

swept file: yes

### Blocking findings

1. **GH-256 changes the dead fallback, not the authoritative runtime.**
   `relay-automation/marathon-drive.sh:9-18` execs `utils/py/marathon_drive.py` when
   `XYZ_PYTHON` is unset, which is the documented default. The new exports are below that exec at
   `relay-automation/marathon-drive.sh:805-808`, so normal runs never execute them. The Python
   driver has no `*_TURN_ROOT` assignment; `_run_relay_drive()` merely copies the existing
   environment at `utils/py/marathon_drive.py:2656-2662`. Thus GH-256 remains unfixed on the
   production/default path. Put the invariant in the Python driver (preferably in the environment
   passed only to relay-drive), not only in the frozen Bash twin.

2. **The GH-256 export set is neither complete nor aligned with marathon routing.**
   The Bash router accepts Claude, Codex, agy, and Aider
   (`relay-automation/marathon-drive.sh:776-784`), but the block exports only agy, Codex, and
   CommandCode. The authoritative Python router additionally accepts Pi and SmallCode
   (`utils/py/marathon_drive.py:1473-1505`). Therefore the reachable guard roots are
   `CLAUDE_TURN_ROOT`, `CODEX_TURN_ROOT`, `AGY_TURN_ROOT`, `AIDER_TURN_ROOT`, `PI_TURN_ROOT`, and
   `SMALLCODE_TURN_ROOT`. `COMMANDCODE_TURN_ROOT` is read by a shim, but CommandCode is not routed by
   `marathon-agent.sh:50-76`; DeepSeek is likewise not a marathon route, and no ox-alpha route was
   found. The current test hard-codes the same incomplete three-name assumption.

3. **GH-255 still gives a non-working primary remedy for a blocked phase file.**
   The phase branch says to rerun with `--target-root` alone
   (`utils/py/marathon_drive.py:327-331`), but the default phase directory remains
   `<root>/marathon-system` even when a target is supplied (`utils/py/marathon_drive.py:926-929`).
   `phase_commit_root()` explicitly retains `root` when that directory is inside the harness repo
   (`utils/py/marathon_drive.py:359-396`). Consequently the same ignored RELAY.md/ESCALATION.md is
   probed again and the rerun blocks again. The file's own contract says the viable cross-repo shape
   is `--target-root <T> --phases-dir <T>/marathon-system` at lines 364-366. Print that complete
   invocation (or make target-root relocate the default) instead of promising that target-root alone
   fixes a phase-file block. `test/gh255-remedy-ordering.sh:68-78` currently pins the bad wording.

4. **The new warning is invisible on the default Python shims, while its Bash behavior is noisy.**
   `rtl_worktree_begin` writes the warning to stderr at
   `relay-automation/relay-turn-lib.sh:726-733`, but Python's bridge captures stderr
   (`utils/py/rtl.py:607-639`) and `RelayTurnLib.worktree_begin()` discards it on success
   (`utils/py/rtl.py:674-679`). The production path therefore still says nothing. On the Bash
   fallback it emits once for every legitimately absent create-new path, which will train operators
   to ignore it. A better discriminator is one warning when the required relative relay file is
   absent, or one aggregated warning when no expected input was seeded; keep individual create-path
   absences debug-only. Ensure the Python bridge actually forwards the selected diagnostic.

### Answers to the review questions

1. **GH-255 membership:** sound at the current call sites. `blocked` stores the exact `p` object
   iterated from `paths` (`utils/py/marathon_drive.py:273-285`), and each call passes the same
   transcript strings in `transcript_paths`. No normalization occurs on either side, so symlinks,
   trailing slashes, and relative/absolute spelling cannot diverge within these calls. A future
   caller passing equivalent-but-differently-spelled lists would misclassify, but no current caller
   does that.

2. **Split calls:** per-call classification is sufficient. The phase call contains no transcripts;
   if it fails, exiting before the transcript call is correct because the phase blockage alone must
   be remedied. If it passes, the transcript-only call has exactly the information it needs. The
   defect is the phase branch's remedy text, not the sequential classification.

3. **Blast radius:** the current default path has no behavior change because of finding 1. On the
   fallback, the global exports overwrite caller-provided fixture roots and leak into later child
   commands, including target gates; the gate scrub does not remove `*_TURN_ROOT`
   (`relay-automation/marathon-drive.sh:514-530`). Scope the overrides to the relay-drive child so
   target-root turns get the invariant without contaminating unrelated gate/test subprocesses.

4. **Completeness:** incomplete, as detailed in finding 2. Only shims actually reachable from the
   marathon router belong in this fix; do not add dormant DeepSeek/CommandCode names merely because
   their standalone files exist.

5. **Warning:** invisible by default and over-broad on Bash; see finding 4.

6. **Tests:** the premise that both are source-text tests is inaccurate.
   `test/gh255-remedy-ordering.sh:31-44` imports and executes the live Python function against an
   actual ignored-path fixture, which is defensible, though it needs a case that proves the printed
   phase remedy is runnable. `test/gh256-target-root-guard-root.sh:26-55` is only a source grep. It
   passes while the export sits after the default exec, while active shims are omitted, and while
   Python swallows the warning. That is exactly a green wording test over broken behavior. A
   hermetic two-repo run needs no network or real model CLI: use the existing stub pattern in
   `test/relay-target-root.sh:69-76` and drive the default Python marathon/relay path far enough to
   record each routed shim's effective root and visible warning.

7. **Missing interactions/docs:** `relay-automation/CONSUMING.md:32-50` still describes manual
   cross-repo root setup and should distinguish standalone shim use from marathon's automatic
   target-root propagation once that behavior is real. Also retain the frozen-twin governance:
   `relay-automation/marathon-drive.sh:2-3` names Python as authoritative, so the durable fix and its
   behavioral test belong on that surface.

### Pre-existing full-file findings

The sweep found two unrelated routing defects in the touched Python driver: `route_agent()` rejects
`gemini*` at `utils/py/marathon_drive.py:1482-1505` before the reviewer check claims Gemini is valid
at lines 1513-1514, and `_probe_agent_bin()` has no SmallCode branch at lines 416-429 even though the
router accepts `smallcode*`. These are not reasons to expand GH-255/GH-256, but they should be parked
explicitly rather than read as covered by this approval.

**Verification:** read-only source and interaction review only. No Git command and no project/test
artifact was executed, per the reviewer-turn containment instructions; the harness owns the gate.
