# RELAY · GH-1169 plan QA: express vendored-host mode
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-19.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1169-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1169-EXPRESS-VENDORED-HOST.md` (the plan; nothing is built yet).
  Requirements: issue https://github.com/HiQS-Labs/XYZ-forge/issues/1169 (operator choice: Forge vendored-host mode).
  Ground against: `utils/py/express.py`, `utils/py/harness_paths.py`, `test/pdda-repo-contract.sh`, `.pdda-mode`,
  `utils/pdda/pdda.sh`, `skills/2-daily/express/SKILL.md`, `test/gh267-express-skill.sh`,
  `test/gh358-wave-reconcile-vendored-paths.sh`, `relay-automation/xyz-vendor.sh` (what a vendored `.xyz/` contains),
  `AGENTS.md` (No new tests; a check that cannot fail), `SOP.md` (express carve-out).
- Operational envelope: a local developer CLI lane driven by one operator. Grade against the issue and plan acceptance
  with commensurate complexity; no new suites, gate machinery or multi-tenant hardening.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-19
- Definition of Done: the plan finds every root-layout assumption on express's docs path in a vendored host, keeps XYZ
  Forge byte-identical, uses a docs gate in hosts that can fail, keeps code hotfixes refused without a registry, and its
  checks would catch a host run that silently skips the gate or lands elsewhere.

### Questions for the Reviewer
1. Inventory: any other root-layout assumption on express's docs-only run/land/resume/closeout path in a vendored host
   (ledger verbs, capture-doc paths, receipts, persist allowlists, `wave_reconcile` resolution, identity checks) that the
   plan misses?
2. Is detecting a vendored host with `harness_paths.is_vendored` on express's own file sound? Could a canonical Forge
   clone or a test fixture be misdetected?
3. Is forcing `PDDA_MODE=full` for the host docs gate the right call (Forge parity; the host's `observe` never fails), and
   is rejecting `.xyz/test/pdda-repo-contract.sh` correct?
4. Gate wiring: is "host pre-push hook if present, else proceed with an explicit no-gate line" acceptable given the landing
   push already uses `XYZ_SKIP_PREPUSH=1`, or does it weaken a real invariant?
5. Are the verification fixture, red controls and smoke enough to detect a host run that skips the gate, mis-records the
   receipt, or resolves the wrong tool copy? GH-831 compliant?
6. Flag anything over- or under-engineered. Cite `file:line`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: Revise the plan before implementation: the required non-docs refusal is not today's behavior, recovery retains root-layout assumptions, and the proposed red control does not establish that express invokes the gate. The operator's host-mode choice is otherwise coherent.
swept file: yes

Reviewed the entire 150-line plan and the complete 1,357-line `express.py`, including existing check/docs/ledger/land/closeout/resume paths, plus the resolver, skill and relevant vendoring/PDDA/reconcile contracts. Pre-existing defects relevant to this change are called out below. Evidence tier: Verify with direct-source fallback. No index exists for this relay worktree; nearest `XYZ-forge` graph generation is `2026-09-01T15:54:30Z`, and coverage reports changed/untracked metadata for the principal code files. Current local source, rather than that graph's stale symbols, grounds findings. No git commands, suites or executable fixtures were run.

- **[Should] F1 — Specify the missing-registry refusal and bind the docs exception to lane identity.** Plan Changes 2 (`PROJECT/1-INBOX/GH-1169-EXPRESS-VENDORED-HOST.md:85-90`) says non-docs refuses `suite-unregistered` “as today.” Current `express.py:601-605` first refuses a missing suite as `suite-missing`, or opens absent `validate.sh` without a guard. A narrow import probe with mocked command results (no git execution), a scratch host containing `.git/` and `test/demo.sh` but no registry, and `args.suite="test/demo.sh", docs_only=False` reached `FileNotFoundError ... '<scratch-host>/validate.sh'` (rc 0 for the probe, exception caught and printed). Correct the current-state claim and explicitly add a vendored non-docs missing-registry refusal before file access. State that **VENDORED and docs_only**, not merely `suite == HOST_DOCS_SUITE`, controls registry exemption and host-gate execution; `--suite 'utils/pdda/pdda.sh run'` without `--docs-only` must not grant a code landing via PDDA.
  Observed input: existing host suite `test/demo.sh`, absent `validate.sh`; proposed normalization also admits the literal host-suite spelling (plan :86-87).
  Affected scope: vendored non-docs runs without a registry, including explicit selection of the host docs command.
  Falsifier: disposable host checks of both inputs return the documented refusal with no traceback or landing; ordinary `--docs-only` still reaches the host gate, and canonical suite admission remains unchanged.

- **[Should] F2 — Include vendored receipt recovery, not just receipt matching.** `express.py:358-366` and the skill's recovery recipe (`skills/2-daily/express/SKILL.md:125-138`) still import/run express from root `utils/py`. The skill executes `bash "$SUITE"`, treating `utils/pdda/pdda.sh run` as one filename, and neither recipe forces full PDDA mode. Plan Changes 5's short paragraph does not address these operations. Extend the existing recovery recipe and generated diagnostic for vendored hosts: correct module/driver location, separate script/argument handling, full-mode/activity-log environment, and the same receipt spelling. Keep canonical recovery unchanged; add a disposable recovery/resume check.
  Observed input: `PYTHONDONTWRITEBYTECODE=1 python3 -c 'import sys; sys.path.insert(0,"utils/py"); import express; print(express.recovery_recipe("a"*40,65,"utils/pdda/pdda.sh run"))'` → rc 0; decisive output: `sys.path.insert(0,"utils/py"); import express` and `runs `bash utils/pdda/pdda.sh run`` (without the required PDDA environment). In the target host express exists under `.xyz/utils/py/`, and the recorded host mode is observe.
  Affected scope: missing committed receipts after an interrupted vendored docs landing.
  Falsifier: follow the revised recipe in the host-shaped disposable clone; an injected PDDA error cannot yield a passing receipt, and a genuine successful recovery produces a committed receipt accepted by `resume --docs-only` on `main`.

- **[Should] F3 — Make the negative control exercise express's landing boundary.** Plan :106-108 proves the host PDDA command can fail, but does not explicitly require the **express run** to fail before publication. A driver that skips Step 7 can pass the proposed clean landing plus separate PDDA red check. Extend that same manual fixture, with no new suite: call non-preview express with the injected invalid doc; assert `suite-red`, unchanged bare-remote tip, no success receipt and no issue-close/ship calls. Also specify a wrong-copy control (root tool decoy versus vendored harness tool), and record/assert the actual landing SHA, base and receipt identity rather than just the command text. Retain nonempty outputs and `provenance.jsonl` under the already named TESTS-RESULTS directory.
  Observed input: plan :104-108 pairs a clean express landing with a red check described only as “makes the host docs gate fail.” Its acceptance at :128-129 repeats that separation.
  Affected scope: manual verification of the newly introduced host docs lane and tool resolution.
  Falsifier: deliberately skipping the host-gate invocation must make this manual verification fail even though standalone PDDA remains red; selecting a root decoy must likewise fail the tool-copy assertion.

- **[Pass] Detection and policy choices are grounded.** Explicit-file `is_vendored` checks the basename two directories above the script and ignores environment overrides (`harness_paths.py:62-77`); the current canonical express path returned `False` in an import-only probe (rc 0). For normal `.xyz/utils/py/express.py` layout this is the intended distinction. Full mode is necessary for nonzero PDDA failures (`utils/pdda/pdda-lib.sh:56-57`); rejecting the vendored contract wrapper is correct because it execs its adjacent PDDA copy (`test/pdda-repo-contract.sh:11`). The host-hook-or-none exception is explicitly authorized by issue #1169, fetched read-only with `gh issue view 1169 -R HiQS-Labs/XYZ-forge --json title,body` (rc 0); retain the visible disclosure.

- **[Nit] Hook reporting should respect the effective hook path.** Plan :91-93 checks `.git/hooks/pre-push`, which can misreport hosts using `core.hooksPath`. When implementing the host-hook message, resolve the effective hook location rather than assuming the default directory. This is a reporting correction, not a request to require a host hook.

[Unverified — needs clone run] Implementation, canonical parity, actual full-mode failure, end-to-end landing/reconciliation and recovery are not established by this plan review. Run the specified verification only in disposable full clones after the plan revisions.

Handing off to Producer (claude-a) — disposition F1–F3, revise the plan and open Round 2; go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
