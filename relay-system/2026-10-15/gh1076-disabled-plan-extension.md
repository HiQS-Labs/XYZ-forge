# RELAY · GH1076 operator-approved corrected-layout plan extension
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(gh1076-operator-approved-corrected-layout-plan-extension): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup

Operator-approved ONE supplemental plan review, not a reset. Preserve original
relay-system/2026-10-15/gh1076-plan-qa.md Escalated3/3 FAIL. The separate extra final QA is unspent.
Read the full canonical plan, specifically corrected exact publication layout and operator extension,
existing wave/router/runner, hosted_lane_publish declaration/receipt retention/recompute consumers,
and retained actual-byte publication-layout observation. Judge the bounded developer-tooling scope:
existing two owners, one unchanged publisher allowlist, no new runner/CLI/cases, activation literalfalse.
No suites or production edits in the linked review worktree. Appending this relay only is permitted.
Check the precise container writer/reader contract, generic receipt fallthrough protection, @1
coexistence and future activation requirements. Concrete deficiencies need actual input/falsifier;
do not demand deployment or a live @2 qualification while activation is prohibited.

- Artifact under review: **.relay-artifacts/GH-1076-CI-POLICY.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1076-CI-POLICY.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-15
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: Ship the corrected plan for the bounded disabled implementation. The exact two-file layout resolves the original publication gap without expanding the publisher, runner or authority surface. This approves a plan, not implemented @2 qualification or activation. Original plan3/3 FAIL and final3/3 history remain intact; the separately authorized supplemental final QA is unspent.
swept file: yes

- [Pass] Exact writer/reader contract is adequate. Artifact .relay-artifacts/GH-1076-CI-POLICY.md:374–388 specifies two ordered phase rows in existing validation.jsonl, lossless UTF-8 payloads, container and original-stream digests, original run IDs/commands/lists/counts, independent strict validation, historical @1 raw-stream semantics and unknown-schema refusal. This explicitly supersedes earlier separate-file wording (:413–414). Each run remains independently attributable; no combined run or synthetic passing total is proposed. Implement the stated strict contract in the existing wave owner, including malformed rows/types/duplicates/order/hash/identity refusal; do not pass the container itself to qualification_summary.
- [Pass] Existing publication/recovery can carry this layout unchanged. utils/py/hosted_lane_publish.py:56,80–90 admits/retains both exact physical filenames; :119–136 reads targets from provenance only; :208–232 restores all retained receipt files before one recompute with --only-receipted --skip-pull. The recompute consumer is the same committed receipt matcher (utils/py/wave_reconcile.py:2223–2238), so implementation must extend committed enumeration and that matcher together as required by artifact :332–351,379–388. Disabled/incompatible @2 must remain unusable there. No publisher widening is needed. This is source inspection plus packaging observation, not an executed publication race.
- [Pass] Independent narrow probe reproduced the retained packaging claim. Exact command below exited **0**, with decisive output **ordered_rows=2; both_original_byte_streams_and_hashes_match=True** and **publisher_regex_matches=[True, True]**. Inputs were a nonempty two-row container and both retained actual component streams. A separate AST-only invocation of existing publisher pure functions returned both paths from declared_paths/receipt_paths, receipt_targets([validation_path]) == ([], []), and retry argv ['--catch-up', '--qualify', '--pr', '1079', '--only-receipted', '--skip-pull']; no git/publisher main/fixture ran. Original streams identify distinct runs f874fa8d4-47453 (75/75) and f874fa8d4-81198 (9/9), both at true tested f874fa8d4d69e2db4f56a8863e6de9b61275842c. These are phase-shape observations, not new qualifying receipts.

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 -B - <<'PY'
import ast, hashlib, json, re
from pathlib import Path
b = Path("TESTS-RESULTS/2026-10-15+GH-1076")
t = ast.parse(Path("utils/py/hosted_lane_publish.py").read_text())
pattern = next(ast.literal_eval(n.value) for n in t.body if isinstance(n, ast.Assign) and any(isinstance(x, ast.Name) and x.id == "RECEIPT" for x in n.targets))
rows = [json.loads(x) for x in (b/"disabled-profile/proposed-validation-bundle.jsonl").read_bytes().splitlines()]
assert [x["phase"] for x in rows] == ["small", "skills-army-hq"]
for x in rows:
    raw = x["telemetry_utf8"].encode("utf-8")
    assert raw == (b/("phase3/component-study/"+x["phase"]+"-validation.jsonl")).read_bytes()
    assert hashlib.sha256(raw).hexdigest() == x["telemetry_sha256"]
print("ordered_rows=2; both_original_byte_streams_and_hashes_match=True")
prefix = "TESTS-RESULTS/2026-10-15+GH-591/wave-f874fa8d4d69e2db4f56a8863e6de9b61275842c/"
print("publisher_regex_matches=" + repr([bool(re.fullmatch(pattern, prefix+n+".jsonl")) for n in ("validation", "provenance")]))
PY
```

- [Pass] Generic fallthrough/coexistence are explicit implementation obligations, not assumed current behavior. Current check_provenance_receipts already reserves qualification namespaces (utils/py/wave_reconcile.py:787–792), whereas validate_pre_merge_receipts directly checks PR/result fields (:866–914). Artifact :385–388 specifically requires the latter to reject @2/unsupported qualification namespaces and requires deployed-consumer/coexistence review before future emission. Current @1 enumeration/matching and historical Small-list replay (:470–478,531–590) must retain their semantics. This addresses the concrete consumer difference without requiring deployment while disabled.
- [Pass] Whole 414-line artifact swept, including historical work, measurements, ownership constraints and superseding continuation. No additional pre-existing plan defect found. Artifact :285–305,313–343 retains two existing owners, fixed existing commands, source-controlled literal false with no override, full fallback, one exact merged development landing, policy/environment identity, no-transfer and no disabled @2 emission/suppression. Runner phase shapes correspond to validate.sh:916–924,1119–1127,1464–1468,1499–1504; the area's eight-suite list is utils/ci-route.sh:35. Artifact :344–364,404–414 retains clone-only checks, no new CI cases, one supplemental final QA, source freeze, ordinary access/403 stop and separate future activation approval. Costly shared-contract risk and pre-activation revert boundary are stated at :300–305. Older status/history is read with its dated continuation, not as refreshed remote state.
- [Unverified — needs clone run] No validate.sh, test/*.sh, pytest, executable fixtures, git commands, source writes, live qualification, publication race or external-state query ran. New writer/reader strictness, current @1 replay equality and red controls require retained disposable-clone evidence and final QA. Graph Verify discovery was attempted: no project exists for this worktree; available foreign-root XYZ-forge generation is 2026-09-01T15:54:30Z, relevant search returned zero, and exact-path coverage reports changed metadata/untracked publisher. Material contracts were read directly from current local source. No exhaustive code-defect, current-development freshness or performance qualification is claimed.

Relay closed (Approved), no further plan-review turn needed. Producer (codex-producer) may implement this approved disabled plan, then use the separately authorized one supplemental final QA and required checks. This grants no activation, merge, deployment or access bypass. Only this relay file was edited; the harness owns its commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
