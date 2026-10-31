# RELAY · GH-1284 final QA: status/tick/packet refuse an uninitialized root
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-31.
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
6. **Commit only the relay file** (`relay(gh1284-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/review-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1284-status-creates-state-2026-10-31/TESTS-RESULTS/2026-10-31+GH-1284/review-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-31
- Definition of Done: (1) on a fresh run root, `factory-primitive status` creates no `state.db` and a following `init` exits 0, per https://github.com/HiQS-Labs/XYZ-forge/issues/1284; (2) `init`, `status`, `tick` on an initialized root behave as before; (3) no legitimate caller in the repo runs `status`/`tick`/`packet` before `init` and would now break; (4) the smoke evidence under TESTS-RESULTS/2026-10-31+GH-1284/ shows main path, adjacent path and a red control; (5) no new tests or suites (GH-831). Code under review: `utils/py/harness.py` on this branch (sweep the whole file for other `connect(instance / "state.db")` callers).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The runtime fix meets the scoped requirement on source inspection and recorded smoke evidence. One shipped evidence script needs a containment correction before approval.
swept file: yes

- [Pass] The guard precedes database creation in all three non-init entry points (`utils/py/harness.py:1005`, `:1123`, `:1277`). The only five `connect(instance / "state.db")` callers are `init_from_prs` (:741), `init_instance` (:807), `make_packet` (:1006), `run_tick` (:1131), and `status` (:1278). Guarding packet/tick prevents the same init-poisoning failure and is in scope. Read all 1,414 lines; no additional initialization-path defect identified. Init bodies are unchanged in the supplied diff.
- [Pass] Recorded main/adjacent/red evidence is sufficient for the targeted runtime change: `TESTS-RESULTS/2026-10-31+GH-1284/smoke.txt:3`–11 shows status refusal, absent database, successful init/status/tick; :13–23 covers tick/packet refusal and repeated initialized tick; :25–29 reproduces the old failure. A non-mutating Python `hashlib.sha256` comparison of harness.py and each artifact against `provenance.jsonl` exited 0 and printed `nonempty; sha256 matches receipt` for all four files. No executable fixtures or suites were run here. Full gate remains [Unverified — needs clone run], as required by this relay's containment rules.
- [Pass] Caller review found no legitimate pre-init dependency in the inspected repo sources. `TESTS-RESULTS/2026-10-29+GH-1248/driver.py:63` reads the initialized canary before ticking; `TESTS-RESULTS/2026-10-29+GH-1257/gh1257-controls.sh:7` seeds with init; `TESTS-RESULTS/2026-10-30+GH-1270/gh1270-controls.sh:25` initializes before tick/packet. Repo literal searches covered runtime, tests, hidden workflow files and recorded controls. Graph project `XYZ-forge` is a different checkout with generation `2026-09-01T15:54:30Z`; coverage reports `metadata_changed` for harness.py, so conclusions use current direct source rather than the stale graph. The packet's code diff adds no suite or gate.
- [Should] Make the recorded smoke script fail closed before cleanup. `TESTS-RESULTS/2026-10-31+GH-1284/smoke.sh:2` uses `cd "$1"; rm -rf temp/factory-primitive`; a missing/mistyped clone argument continues in the caller's checkout and deletes its runtime tree. Line 22 repeats the relative recursive deletion. This violates the repository's proven-target cleanup rail even though the successful receipt used a disposable clone. Fix: require and resolve an existing disposable clone, stop on failed cd, and validate an absolute cleanup target at each use (prefer an exclusively owned run subtree). Keep this a manual evidence script; add no suite. Update artifact hashes if the script changes; historical output can remain labeled as the original run.
  Observed input: `smoke.sh:2`, clone argument `/__gh1284_missing_clone__`. Safe control-flow probe replacing deletion with printing: `bash -c 'cd /__gh1284_missing_clone__; printf "cleanup would continue in: %s\n" "$PWD"'`; exit 0, output `cd: /__gh1284_missing_clone__: No such file or directory` followed by `cleanup would continue in: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.fovLk9`. No deletion was executed.
  Affected scope: Invocations of this evidence script with an absent, invalid or unintended clone directory, and both cleanup sites.
  Falsifier: An invalid clone argument must exit nonzero before reaching cleanup; a valid disposable clone must constrain cleanup to its resolved, explicitly owned runtime subtree. If both properties already held at line 2, this finding would be unnecessary; the safe probe demonstrates they do not.

Handing off to Producer (claude-a) — correct the smoke-script cleanup containment, disposition the finding, and reopen review. Go to the Producer window and say 'take your turn'.

### Producer · Round 1

- **[Should] smoke.sh cleanup containment — Implemented.** `smoke.sh` now resolves the clone argument with `cd ... && pwd -P` and exits 2 if that fails, refuses any path not ending in `-verify` or lacking `utils/py/harness.py`, and deletes only through `clean()`, which checks the absolute target equals `<clone>/temp/factory-primitive`. One `rm -rf` remains, inside `clean()`.
  - Falsifier run: `smoke.sh /__gh1284_missing_clone__` → rc 2 before any cleanup; `smoke.sh <task clone>` → rc 2 `refused: ... is not a disposable *-verify clone`, task clone has no `temp/factory-primitive`; `smoke.sh <verify clone>` → rc 0, output identical to the recorded `smoke.txt` except the header line.
  - `provenance.jsonl` row 2 records the new `smoke.sh` hash; `smoke.txt` stays the original run (row 1 keeps the pre-hardening script hash, labelled).
- [Pass] items: no action.
- Full gate: runs on push via the pre-push hook (classified full route for `utils/py/harness.py`).

Handing off to Reviewer (codex) for Round 2 — re-check the smoke-script fix.

### Reviewer · Round 2

VERDICT: PASS
Basis: Ship within the packet's single-operator envelope. The Round 1 cleanup finding is resolved; the targeted source change and recorded main/adjacent/red evidence meet the review contract. Full gate execution remains outstanding.
swept file: yes

- [Pass] Round 1 containment correction accepted. `TESTS-RESULTS/2026-10-31+GH-1284/smoke.sh:4` resolves the clone and exits on failed resolution; :5–7 reject a non-verify/missing-harness directory and failed cd; :8–10 constrain cleanup to the absolute clone runtime target. Both cleanup sites call that function (:10, :29). Safe guard-only probe (no cleanup or fixture body executed): `lines = Path("TESTS-RESULTS/2026-10-31+GH-1284/smoke.sh").read_text().splitlines(); prefix = "\n".join(lines[2:7]) + '\nprintf "guard accepted\\n"\n'; subprocess.run(["bash", "-c", prefix, "guard-probe", arg], capture_output=True, text=True)`, for `arg="/__gh1284_missing_clone__"` and this worktree's absolute path. Probe driver exited 0; both subprocesses exited 2. Decisive output: `cd: /__gh1284_missing_clone__: No such file or directory` and `refused: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.GtK51R is not a disposable *-verify clone`.
- [Pass] Read the entire packet and all 1,414 lines of `utils/py/harness.py` again; no additional pre-existing defect identified in this sweep. The only instance database connection sites remain :741, :807 (init), :1006, :1131 and :1278; the latter three have guards at :1005, :1123 and :1277 before any database creation. The guard's quoted failure is `instance not initialized; run init first` (:103). The packet's diff changes no init body and adds no suite/gate. No new legitimate pre-init dependency was identified in the caller search; the driver reads its initialized canary (`TESTS-RESULTS/2026-10-29+GH-1248/driver.py:63`), while the adjacent controls seed first (`TESTS-RESULTS/2026-10-29+GH-1257/gh1257-controls.sh:7`, `TESTS-RESULTS/2026-10-30+GH-1270/gh1270-controls.sh:25`). Graph tools are unavailable in this turn; current direct source and literal searches provide the evidence.
- [Pass] Evidence integrity: non-mutating Python check `assert data and hashlib.sha256(data).hexdigest() == digest`, using the latest per-artifact hashes from `TESTS-RESULTS/2026-10-31+GH-1284/provenance.jsonl:1`–2, exited 0 and printed `nonempty; sha256 matches latest receipt` for harness.py, smoke.sh, smoke.txt and SUMMARY.md. Row 2 explicitly labels the original script hash as pre-hardening. Recorded `smoke.txt:3`–11 shows refusal without state creation followed by successful init/status/tick; :13–23 covers adjacent refusal and repeated tick; :25–29 supplies the failing unpatched control.
- [Unverified — needs clone run] No full gate, suite, executable fixture or runtime smoke was run in this reviewer worktree. The harness must obtain final-state gate evidence in a disposable full clone; relay approval does not attest that pending run.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
