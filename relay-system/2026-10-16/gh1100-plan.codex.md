# RELAY · GH-1100 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-16.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh1100-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1100-JOG-TARGET-ROOT.md` and `PROJECT/2-WORKING/recon-gh1100-jog-target-root.md`; read cited source files directly
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-16
- Definition of Done: Review the committed plan against issue #1100 and its recorded red control. Validate downstream root/phase behavior, same-root --target-root compatibility, old packet and vendored compatibility, retry paths, ratings and commensurate complexity. No unrequested multi-tenant scope. Reviewer may write only this relay; do not run mutation-heavy tests in a worktree. Approve only if grounded and sufficient.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Producer · codex-producer · 2026-10-16
**Did:** Committed recon, red control and plan at 6f93fe1d. No runtime edits yet.
**Review this:** Both dispatch sites, harness_paths, swarm_preflight invocation builder, and marathon_drive root/phase/target consumers. Packet env lacks harness pin; target alone leaves root phases exposed. The proposed helper should remain small.
**Verification:** Intercepted run_marathon_phase captured nonempty dispatch and failed missing-target assertion; committed provenance and command.
**Commit:** 6f93fe1d

### Reviewer · Round 1 · codex · 2026-10-16
**Ship — plan approved.**
swept file: yes
**VERDICT: PASS**
**Basis:** Read both complete plan/recon documents and the current source at the material dispatch, packet, resolver, phase and containment seams. No additional pre-existing defect found in the two reviewed documents. Approval covers the plan, not runtime implementation or landing readiness.

- [Pass] The fix covers both independent root inputs without changing standalone policy: Marathon resolves tools through harness_home and coordination through MARATHON_ROOT (utils/py/marathon_drive.py:1121–1128), defaults phases under that root (:1368), and passes target to relay-drive and shim roots (:3384–3416). Pinning both env values plus an explicit missing target addresses the recorded ambient-XYZ_HARNESS failure; argv alone would leave phase output exposed. The committed red-control.txt records nonempty dispatch, primary resolved_root and “AssertionError: missing explicit --target-root”; provenance.jsonl records exit 1. Its loader was mocked, so it is adapter evidence rather than a validated-packet integration run.
- [Pass] The executable-parent assumption fits the supported producer layouts: compute_default_root selects relay-automation/marathon-drive.sh or .xyz/relay-automation/marathon-drive.sh (utils/py/swarm_preflight.py:27–35); the structured builder absolutizes that command (:1098–1102). The loader does not require harness_home (utils/py/jog_run.py:84–128). Deriving tooling from argv[0] preserves old packets and lexical .xyz layout without schema growth.
- [Pass] Same-root explicit target is supported by the existing containment path: relay-drive refuses only a relay outside target (utils/py/relay_drive.py:232–241); the planned root places the default relay below that target (utils/py/marathon_drive.py:2089–2090). Same-repository normalization is already documented and implemented in relay-automation/relay-turn-lib.sh:298–320. Keep explicit cross-repo targets unchanged; this plan does not promise to repair an already-invalid cross-repo relay layout.
- [Pass] Both dispatch paths need the shared policy: run dispatch merges env at utils/py/jog_run.py:591–608; gate retry independently does so at :798–802; retry-build delegates to run_marathon_phase at :863. Plan step 2 explicitly preserves lock/idle policy and packet immutability. The small shared helper and existing argv adapter are commensurate with these two sites; no multi-tenant machinery is warranted.
- [Pass] Narrow non-mutating probe, exit 0: command was `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'`, with AST extraction of the current `build_marathon_invocation_artifact` and `_marathon_argv_from_invocation` into an os-only namespace, then root/vendored/explicit packets, deletion of optional harness_home, adaptation, and assertions on packet JSON equality and target presence. Decisive output: root and vendored “target_present: false”; explicit “target_present: true”; all three “packet_unchanged: true”; derived tooling homes were respectively task root, task-root/.xyz, task root, while coordination stayed task root. This corroborates the current omission and derivation assumptions; it does not execute the proposed helper.
- [Pass] Ratings and bounded scope are grounded in the local record: releases.sql:867 carries 80/85/50/90 without override, matching plan:33. Plan:39–45 requires red/green provenance, target-only falsification, retries, vendored boundaries, disposable-clone verification and final QA; no new tests or gates are proposed.
- [Unverified — needs clone run] Runtime compatibility, real phase/commit behavior and final required gates remain implementation acceptance work under plan:39–41. No validate.sh, test/*.sh, pytest, builders or executable fixtures ran here.
- [Unverified — external issue unavailable] `gh issue view 1100 --repo HiQS-Labs/XYZ-forge --json title,body,state` exited 1: “error connecting to api.github.com”; web open of the issue returned “Cache miss”. Issue-specific history and the severity change from 75 are taken from the seeded plan/recon, not independently refreshed. No invented issue-state claim.
- Evidence limits: Verify tier, graph project XYZ-forge generation 2026-09-01T15:54:30Z; graph search returned all 3 matching adapter/loader/builder symbols, no pagination remaining. Coverage reported changed/missing metadata and the gh280 parse gap at 628–629; material claims use current source reads, including that gap. No repository-wide audit claim.

Root cause: packet omission plus inherited harness selection lets Jog dispatch escape the chosen clone; fix site: Jog's shared dispatch policy; why here: preserve standalone producer/resolver behavior while giving both Jog dispatch paths explicit roots.

Relay closed (Approved), no further turn needed. Producer may proceed with accepted-start and implementation; harness owns the relay-only commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
