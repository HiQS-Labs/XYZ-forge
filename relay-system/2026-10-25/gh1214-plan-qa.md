---
Goal: Independent plan QA (pre-fire) for marathon #1214 — five member plans + MARATHON.yaml
Date: 2026-10-25
NEXT: Reviewer
STATUS: Approved
---

# Context

You are the independent plan reviewer (GH-784 Wave Plan QA, `/start-task` step 6 parity) for a marathon that has **not fired yet**. One strict chain of five lanes; builder `agy`, post-build reviewer `codex`; default per-phase gate `bash validate.sh`.

Operational envelope: local developer harness (Bash + stdlib Python, one operator). Commensurate complexity; no enterprise fail-safes. **GH-831 D7:** a new `test/` suite, `validate.sh` registry entry or gate machinery (guards, lanes, runners, telemetry stages) is itself a finding — do not ask for one. Verification is existing suites + manual checks under `TESTS-RESULTS/`.

Read in full:
- `PROJECT/2-WORKING/GH-1214-LESSONS-READBACK/CAPTURE.md` and `MARATHON.yaml`
- `PROJECT/2-WORKING/GH-1222-RELEASES-LIVE-MANIFEST-COUNT.md` (p1)
- `PROJECT/2-WORKING/GH-1221-IMPROVE-LOOP-BUILD-CAN.md` (p2)
- `PROJECT/2-WORKING/GH-1219-CONSULT-BLIND-B-RECONCILE.md` (p3)
- `PROJECT/2-WORKING/GH-1218-LESSONS-READ-BACK-EVIDENCE.md` (p4)
- `PROJECT/2-WORKING/GH-1220-MARATHON-RESUME-REUSES-PHASE.md` (p5)

and the code each one cites (verify every `file:line` claim you rely on).

Questions:

1. **Write-sets.** For each phase, is the declared `artifact` / contract write-set sufficient to complete the plan *and* pass `bash validate.sh` without a containment revert (exit 6)? Name any file the builder will predictably have to touch that is missing (e.g. a package tarball, a suite whose pinned assertion becomes untrue, a vendored copy), or any entry that is unnecessary.
2. **p1 #1222.** Is `COUNT(DISTINCT issue_ref_id)` correct for both `_live_manifest_count` and migration 004's backfill (`utils/py/releases_app.py` ~2517-2533, ~824-833)? Any caller relying on the old count?
3. **p2 #1221.** Is the snapshot/compare/restore design in `relay-automation/improve-loop.sh` sound and minimal? Does it handle the default `STATE_DIR`, ignored paths and pre-existing dirty files without false positives? Any bash-3.2 or `-z` parsing pitfalls the plan should name?
4. **p3 #1219.** With `consult.sh` frozen and execing `consult.py` by default, is the Python-only change + skill text complete? Will the neutral-payload stripping hit every identity source (attestation, stamps, banners)?
5. **p4 #1218.** Is `rtl_turn_prompt` (`relay-automation/relay-turn-lib.sh:995`) truly the single point every shim (incl. SmallCode) reaches? How should the reader resolve `LESSONS-LEARNED.md` (RTL_ROOT vs git toplevel) so it is silent in vendored repos without the file? Will the added block break any prompt-pinning suite?
6. **p5 #1220.** Is passing `MARATHON_CONFIG_SHA256` by environment from `marathon_drive` to its relay-drive child sound (does the env reach `relay_drive.py` through `relay-drive.sh`)? Is the identity tuple computable at both write and compare time? Does legacy-accept keep `jog` and existing attestation suites green?
7. **Order and coupling.** Is the chain order p1→p5 right, given p4/p5 modify code the running driver uses? Any cross-lane dependency the order violates?
8. **Over/under-engineering.** Anything to cut, or anything missing that would make a phase fail its gate?

Flag anything wrong, missing, mis-scoped, or over/under-engineered. Cite `file:line`. Every `[Blocker]` or `[Should]` requesting a change MUST carry `Observed input:`, `Affected scope:`, `Falsifier:` lines (GH-681); a `[Blocker]` must cite an observed failure. Write your verdict in one reviewer block below and set `STATUS: Approved` if the plans may fire as written, otherwise hand back with `STATUS: Changes requested`.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

### Codex reviewer — 2026-10-25

Verdict: Changes requested before fire. The chain order and declared primary write-sets are otherwise sound: p1's `COUNT(DISTINCT issue_ref_id)` is correct for the append-only shipped-plus-redial shape (`utils/py/releases_app.py:114-123,2517-2522,824-833`), and the only callers are baseline capture/rendering rather than consumers that require a row count (`utils/py/releases_app.py:2502-2505,2533,2561`). `rtl_turn_prompt` is reached by the Python wrapper (`utils/py/rtl.py:849-852`) and each Bash shim, including SmallCode (`relay-automation/smallcode-turn.sh:26-28`); resolve the lessons file from `RTL_ROOT`, with a quiet git-toplevel fallback only if it is empty. The environment transport in p5 will reach `relay_drive.py`: `marathon_drive.py` passes `env2` to `relay-drive.sh` (`utils/py/marathon_drive.py:3386-3417`) and the Python-default wrapper `exec`s its Python child (`relay-automation/relay-drive.sh:9-18`).

[Should] p2's proposed status listings plus tracked-file copies cannot restore a pre-existing ignored file that the build changes; `git status --porcelain -z --untracked-files=all --ignored` records state/path, not its former bytes. Amend the plan to snapshot every pre-existing off-ALLOW ignored/untracked path (including directory shape and bytes) before the build, then restore that snapshot and remove only post-build additions; use NUL-safe path handling and state explicitly that `$STATE_DIR` is excluded by a normalized repo-relative prefix. This preserves pre-existing dirty files while keeping the default tracked state dir harmless.

Observed input: The p2 plan requires restoration of a "previously existing ignored file" but names content copying only for tracked files (`PROJECT/2-WORKING/GH-1221-IMPROVE-LOOP-BUILD-CAN.md:45-55`); ignored paths are intentionally invisible to ordinary porcelain in the cited current design (`relay-automation/improve-loop.sh:69-76,118-126`).

Affected scope: p2 plan/contract and its manual red/green receipt; no additional production artifact is required beyond the declared `relay-automation/improve-loop.sh`.

Falsifier: A manual check that creates ignored `cache/x` with known old content before the build, mutates it during the build, then proves rejection restores exactly the old content and mode while a newly created ignored sibling is removed.

[Should] p3 must specify a neutral Markdown projection for JSON-mode Gemini answers, not a raw-file copy. JSON envelopes can retain model/provider/metadata even when the visible response is neutral; current validation already extracts only `.response` from a JSON transcript (`utils/py/consult.py:208-214`), while JSON mode writes `${label}.gemini.json` (`utils/py/consult.py:664-672`) and skips text-stamp rewriting (`utils/py/consult.py:876-885`). The plan's no-advisor-name acceptance therefore needs its manual check to cover JSON mode and inspect the A/B payloads, not merely named originals.

Observed input: The p3 plan says to write a neutral copy of "each answer" after stamping (`PROJECT/2-WORKING/GH-1219-CONSULT-BLIND-B-RECONCILE.md:48-54`) without defining the JSON extraction boundary.

Affected scope: p3 plan/contract, `utils/py/consult.py`, and its declared manual receipt only.

Falsifier: A stubbed `CONSULT_GEMINI_JSON=1` run whose original JSON contains identifying envelope fields but whose `answer-A.md` contains only the decoded response and no advisor/model/provider strings.

[Blocker] p5's `config_sha256` is not currently bound by the attestation trailer. A changed value in the JSON record therefore leaves `relay_attest.load()`'s existing trailer/digest relationship valid, allowing a mismatching finished phase to appear matching. Amend p5 to serialize the optional `config_sha256` into `relay_attest.trailer_text` when present, validate it as a non-empty string when present, and make its manual receipt demonstrate that changing the record field causes `load()` to refuse (while a legacy record/trailer remains accepted). This remains an `attest@1` optional-field extension and stays within p5's already-declared `utils/py/relay_attest.py` write-set.

Observed input: Probe `python3 -c '... print(relay_attest.trailer_text(a) == relay_attest.trailer_text(b)) ...'` exited 0 and printed `True` when the only difference between `a` and `b` was `config_sha256=old` versus `config_sha256=new`; `trailer_text` currently emits only task/reviewer/status/head/added-range/digest (`utils/py/relay_attest.py:203-210`), whereas `load()` accepts optional non-null string fields generically (`utils/py/relay_attest.py:253-272`).

Affected scope: p5 plan/contract, `utils/py/relay_attest.py`, `utils/py/relay_drive.py`, and its declared manual receipt; no frozen twin or schema-version change.

Falsifier: A completed attestation with `config_sha256` in both record and trailer loads; changing only the stored field makes `relay_attest.load()` reject because its reconstructed trailer no longer matches, while removal of the optional field from a legacy record still loads.

### Producer (claude-a, orchestrator) — Round 1 response

All three findings accepted and folded into the plan docs (commit follows this block):

- **[Blocker] p5 trailer binding** — `GH-1220` doc: `trailer_text` includes `config_sha256` when present, `load()` validates it non-empty when present and refuses a record whose stored field no longer matches its trailer; legacy records unchanged; manual case (e) added; contract criteria updated.
- **[Should] p2 ignored-file bytes** — `GH-1221` doc: pre-build snapshot now saves bytes/mode/shape of every pre-existing off-ALLOW path (tracked-dirty, untracked, ignored), NUL-safe, `$STATE_DIR` excluded by normalized repo-relative prefix, fail-closed on snapshot error; restore returns pre-existing paths exactly and removes only new paths; manual case (d) is now your falsifier (`cache/x` old bytes+mode restored, new ignored sibling removed).
- **[Should] p3 JSON mode** — `GH-1219` doc: JSON-mode answers get a Markdown projection of the decoded `.response` only (the `consult.py:208-214` boundary), never the raw envelope; manual check adds a stubbed `CONSULT_GEMINI_JSON=1` run with identifying envelope fields.

Please verify the amendments and approve or hand back.

### Codex reviewer — 2026-10-25 (Round 2)

Verdict: Changes requested before fire. The producer fully resolved the earlier p3 JSON-envelope and p5 attestation-binding findings: p3 now confines JSON payloads to decoded `.response` (`PROJECT/2-WORKING/GH-1219-CONSULT-BLIND-B-RECONCILE.md:56,64-69`), and p5 makes the optional field part of the validated trailer (`PROJECT/2-WORKING/GH-1220-MARATHON-RESUME-REUSES-PHASE.md:66-76`). p2's revised restoration snapshot is also necessary, but its detection predicate remains insufficient for a content-only change inside an already-present ignored directory.

[Should] p2 must compare a content-sensitive, NUL-safe manifest (or equivalent tree digest) for every pre-existing off-ALLOW ignored/untracked path, not only the before/after porcelain listings. `git status --porcelain --ignored` describes status/path; it cannot report that `cache/x`'s bytes or mode changed while `cache/` remains an ignored path. Without this, the stated case (d) can miss the violation entirely, so the existing rejection/restore path never runs. Amend step 2 and the manual check to require a same-path ignored-file content/mode mutation (with no new sibling) be detected, rejected, and restored.

Observed input: The amended plan still says to use "the same listing" and treat only paths reported new or changed as violations (`PROJECT/2-WORKING/GH-1221-IMPROVE-LOOP-BUILD-CAN.md:47-55`), despite separately requiring byte/mode restoration for an existing ignored `cache/x` (`:49,53,59`). The current loop has no post-build write detector at all (`relay-automation/improve-loop.sh:118-151`), so the planned listing is the only proposed detection input.

Affected scope: p2 plan/contract and its manual receipt; the declared `relay-automation/improve-loop.sh` artifact is sufficient—no new suite, gate, or artifact is needed.

Falsifier: In a throwaway repo, create ignored `cache/x` with known bytes/mode, have the build change only those bytes/mode (no new path), and demonstrate rejection plus exact restoration; a post-build path-only porcelain comparison will not satisfy this check.

[Should] p5's acceptance list must include manual case (e), which is the trailer-tamper proof added to resolve the prior blocker. Otherwise the formal acceptance criteria omit the only evidence that the new binding actually rejects a changed stored field.

Observed input: The manual plan requires case (e) (`PROJECT/2-WORKING/GH-1220-MARATHON-RESUME-REUSES-PHASE.md:71-76`), but Acceptance still requires only cases (a)-(d) (`:139-143`).

Affected scope: p5 plan acceptance wording only; no production write-set or extra verification machinery.

Falsifier: The acceptance section explicitly requires cases (a)-(e), including a refusal after altering only `config_sha256`.

### Producer (claude-a, orchestrator) — Round 2 response

Both findings accepted:

- **[Should] p2 content-sensitive detection** — `GH-1221` step 2 now records a pre-build NUL-safe content manifest (path, mode, content hash) for every pre-existing off-ALLOW path (tracked-dirty, untracked, ignored; `$STATE_DIR` excluded) and detects new/removed paths AND same-path byte/mode changes; manual case (d) is now the in-place `cache/x` mutation with no new path.
- **[Should] p5 acceptance** — `GH-1220` Acceptance now requires cases (a)–(e), naming the trailer-tamper refusal.

Please verify and approve or hand back.

### Codex reviewer — 2026-10-25 (Round 3)

Verdict: Approved — the five plans may fire as written. The amended p2 design now detects same-path ignored-file byte/mode changes using the NUL-safe content manifest and restores the preserved pre-build bytes (`PROJECT/2-WORKING/GH-1221-IMPROVE-LOOP-BUILD-CAN.md:47-59`); p5’s acceptance explicitly includes the trailer-tamper red control (`PROJECT/2-WORKING/GH-1220-MARATHON-RESUME-REUSES-PHASE.md:68-76,139-143`). The declared artifact sets match the plan contracts and `MARATHON.yaml` (`PROJECT/2-WORKING/GH-1214-LESSONS-READBACK/MARATHON.yaml:18-53`), with no missing frozen twin, package, or pinned-suite artifact identified.

Static verification confirms the remaining seam claims: p1’s `issue_ref_id` is non-null (`utils/py/releases_app.py:547-553`), so `COUNT(DISTINCT issue_ref_id)` has the intended row-to-issue behavior; p3’s JSON projection is correctly scoped to the validator’s decoded `.response` boundary (`utils/py/consult.py:203-214; PROJECT/2-WORKING/GH-1219-CONSULT-BLIND-B-RECONCILE.md:48-69`); p4’s shared prompt helper remains the single shim path, including SmallCode (`utils/py/rtl.py:849-852; relay-automation/smallcode-turn.sh:26-28`); and p5’s child environment is passed directly to `relay-drive.sh` (`utils/py/marathon_drive.py:3362-3417`), whose Python-default path execs `relay_drive.py` (`relay-automation/relay-drive.sh:9-18`). Once implemented, the optional field will be protected because `load()` reconstructs and verifies `trailer_text` against both the stored hash and relay body (`utils/py/relay_attest.py:301-305`).

Scope note: this was the requested pre-fire static plan QA. No executable fixtures or test suites were run in this linked worktree; each phase’s required disposable-clone/manual receipt and harness gate remain its execution proof.
