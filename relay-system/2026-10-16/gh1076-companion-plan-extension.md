# RELAY · GH1076 companion classification plan extension
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
6. **Commit only the relay file** (`relay(gh1076-companion-plan-extension): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1076-companion-plan-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file relay-system/2026-10-16/gh1076-companion-plan-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-15
- Definition of Done: The complete scoped questions and acceptance contract in gh1076-companion-plan-packet.md and the latest canonical plan section. One independently reviewed turn1/1; preserve all prior counters and accepted local trust.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

Ship the scoped plan to implementation.

VERDICT: PASS

Basis: The bounded correction has a coherent immutable carrier contract, preserves the original functional-scope predicate, and requires fresh landing qualification. This approves the plan only, within the explicitly accepted local trust boundary; it does not approve unwritten code, qualification results, publication readiness or activation.

swept file: yes

Read the entire seeded packet and canonical GH-1076-CI-POLICY.md, including historical failures and superseding sections, the retained receipt-companion recon/design, and the separate AUTHORIZATION.md. Inspected current router in full and the relevant wave selection, strict summary, premerge admission, writer, replay and recovery callers, plus hosted_lane_publish.py. No additional pre-existing defect found in the reviewed packet/plan. This is not an exhaustive audit of unrelated reconciler lifecycle code. Graph lookup used XYZ-forge generation 2026-09-01T15:54:30Z; coverage reported changed/missing metadata for the four requested source/plan paths, so current source reads replace stale graph evidence here.

- [Pass] **Scope and identities:** canonical plan lines 616–618 require C to be the actual PR head, one single-parent commit after S, exactly two new regular100644 sibling files, and matching new B→M paths/blobs. The remaining complete raw B→M predicate is preserved, including modes/status/exclusions. Thus the proposed exclusion cannot excuse a third functional path merely because it is under TESTS-RESULTS. Implement the contract as written; no requested change.
- [Pass] **Accepted trust, not authentication:** plan lines 606 and 612–614 explicitly limit the supported schema1.0 subset, bind original stream bytes, require strict historical Small telemetry, and acknowledge a fully consistent fabricated local story cannot be authenticated. AUTHORIZATION.md explicitly accepts classification-only local proof. This is sufficient for the authorized classification decision; it is not independent producer attestation. No new witness/service is needed for this scope.
- [Pass] **One owner and compatibility:** plan lines 612 and 618–620 retain the legacy default reader, require the same resolver for selection/writer/replay, bind the empty or populated descriptor, and version CONTENT_PROFILE to skills-army-content@2 while retaining wave-qualification@1 behavior. Current seams are wave_reconcile.py:675 (profile replay), :734 (committed qualifications), :753 (selection), :798 (writer), :1044 (legacy premerge reader), and :2457 (only-receipted recovery). These are the right existing owners to extend; generic schema1.0 must remain classification data rather than postmerge PASS.
- [Pass] **Fresh execution and fatal failures:** plan lines 620 and 626–628 require real S Small proof followed by fresh independent Small72/area8 streams at controlled M, with true launched identities. Current wave_reconcile.py:873–887 makes command/config/process failures fatal, :898–907 distinguishes environment drift from incomplete-proof fallback, and :918–934 retains the publisher-compatible two physical files. hosted_lane_publish.py's RECEIPT allowlist and receipt_targets consume those existing paths without a companion-path exemption. Preserve these contracts as written.
- [Pass] **Feasible acceptance, bounded authority:** plan lines 624–630 specify disposable full clones, dependency copying and disclosed setup interception, real qualifying commands, manual negative controls, unchanged existing suites, pinned historical replay, one final review and normal publication gates. Plan lines 602 and 606 preserve historical FAIL/counters, cap each extension at1/1, name disable/revert rollback and stop signals; line 630 prohibits merge/activation/cleanup. No new test machinery or installation is needed by the proposed procedure.
- [Pass] **Narrow parser reuse observation:** the command below exited **0**. It extracts only the current canonical pure summary function, checks nonempty retained streams, and changes a suite omission field in memory as a red control. Decisive output: `small bytes 23509 PASS 75 75 f874fa8d4-47453`; `skills-army-hq bytes 3146 PASS 9 9 f874fa8d4-81198`; both controls printed `skip-control REJECTED: profile phase contains extra stages, retries, omissions or drift`. Sources: wave_reconcile.py:568–627 and TESTS-RESULTS/2026-10-15+GH-1076/phase3/component-study/{small,skills-army-hq}-validation.jsonl. This establishes only reuse of the present parser with retained bytes, not execution or correctness of the proposed resolver.

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PY'
import ast, json, re
from pathlib import Path
source = Path("utils/py/wave_reconcile.py").read_text()
fn = next(n for n in ast.parse(source).body if isinstance(n, ast.FunctionDef) and n.name == "qualification_summary")
ns = dict(json=json, SMALL_NON_SUITE=("tier2:pdda", "python:test_python_layer.py"))
exec(compile(ast.Module(body=[fn], type_ignores=[]), "<canonical-summary>", "exec"), ns)
router = Path("utils/ci-route.sh").read_text()
root = Path("TESTS-RESULTS/2026-10-15+GH-1076/phase3/component-study")
for phase, registry, extra in [("small", "small", ns["SMALL_NON_SUITE"]), ("skills-army-hq", "skills_army_hq", ())]:
    raw = (root / (phase + "-validation.jsonl")).read_bytes()
    assert raw
    rows = [json.loads(line) for line in raw.splitlines() if line.strip()]
    sha = rows[0]["commit"]
    suites = re.search(r'^SUBSYSTEM_TESTS_' + registry + r'="([^"]*)"$', router, re.M)[1].split()
    summary = ns["qualification_summary"](raw, sha, suites, extra, strict=True)
    print(phase, "bytes", len(raw), "PASS", summary["passed"], summary["total"], summary["run"])
    next(r for r in rows if r.get("event") == "suite")["skip_lines"] = 1
    try:
        ns["qualification_summary"]("\n".join(json.dumps(r) for r in rows), sha, suites, extra, strict=True)
    except ValueError as e:
        print(phase, "skip-control REJECTED:", str(e))
    else:
        raise AssertionError("skip control accepted")
PY
```

- [Unverified — needs clone run] The correction does not exist yet. Actual S→C→M admission, fresh qualification, full negative/history matrix, publication gates and final implementation review remain pending under plan lines 625–630. No validate.sh, test/*.sh, pytest, executable fixture or git command was run in this turn. No performance saving or live hosted qualification is claimed.

Relay closed (Approved), no further turn needed. Producer may proceed with the authorized implementation and separate final-review1/1; all prior counters and accepted local trust remain intact. Harness owns the relay-file commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
