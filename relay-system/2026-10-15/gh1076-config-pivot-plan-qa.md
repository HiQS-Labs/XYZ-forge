# RELAY · GH1076 operator-pivot optimized CI configuration plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
-->

NEXT: codex-producer
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
6. **Commit only the relay file** (`relay(gh1076-operator-pivot-optimized-ci-configuration-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1076-config-pivot-plan-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file relay-system/2026-10-15/gh1076-config-pivot-plan-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
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
Basis: Approve the configuration-pivot PLAN for bounded implementation, not implementation completion or live qualification. The packet's operational envelope and the complete canonical plan (all 500 lines, including superseded history) were reviewed. No concrete blocking contract defect found. Accepted selective-testing risk is explicit; the evidence contract is Costly, with full fallback and disable/revert paths.
swept file: yes

- [Pass] Existing configuration owner/path/precedence are grounded in `utils/py/device_config.py:29`, `:46`, `:76`, `:95`. The pivot explicitly requires optional strict validation, boolean default false, rejection of malformed lower tiers even when masked, and unchanged ordinary callers/output (`PROJECT/2-WORKING/GH-1076-CI-POLICY.md:436`). Current permissive coercion at device_config.py:102 is an implementation target, not evidence that strict resolution already exists. Preserve the existing absent/empty-file convention for ordinary callers (`test/gh549-work-events.sh:253`).
- [Pass] Runtime/hosted boundary and disable paths are explicit at canonical plan:444 and :453: only wave qualification changes; local pre-push/ci-local/explicit validate retain their contract; hosted env defaults to '1' independently of the Mac file, repository variable '0' disables future optimization. Isolated local verification and parent-coordinated primary enablement are required at :461. Exact-main full command remains `.github/workflows/ci.yml:203`. This is planned future hosted activation, not a settings change or live-run claim.
- [Pass] Scope is one complete merged development PR, tested=landing, exact head/base and raw modified regular tracked top-level package text; mixed/unknown/high-risk inputs return full (canonical plan:468). The earlier detailed sequence explicitly excludes operational/security/permission changes, additions, renames, mode changes and symlinks. This does not authorize generic Medium selection, candidate/environment verdict transfer, mutable batch authority or bypass.
- [Pass] Publisher-compatible two-file layout is concrete: canonical plan:367 describes two ordered container rows preserving each original stream; publisher allowlist/retention at `utils/py/hosted_lane_publish.py:80` and :89 accepts those logical paths, and :119 ignores validation content as provenance. Read-only probe below independently checked the retained actual bytes/hashes/run identities and a failing filename control. This establishes storage compatibility, not executed publication recovery.
- [Pass] Phase/evidence requirements are stated at canonical plan:474 and :482: capture configuration before child sanitation; strip policy/path overrides from suite children; preserve @1; reject disabled/error @2; independently validate fixed Small and area runs, real non-shell stages, counts, width, identities, failures/retries/skips. Current runner selection/stages at `validate.sh:924`, :1119, :1439 and :1465 support the 75/9 phase shape. Generic premerge namespace fallthrough at `utils/py/wave_reconcile.py:821` is explicitly required to be closed before emitting @2; current source is not claimed to implement that guard.
- [Pass] Bounded verification and rollout stop points are actionable at canonical plan:487 and :494: existing covering checks, manual strict-config and receipt controls, historical @1 equality, independent final QA before frozen-source full push gate, natural hosted results, no new cases or live @2 claim for this Large change. Disable returns Medium full; no prior narrowed run becomes retroactively full-qualified. The existing receipts-first recovery remains bounded; config/environment mismatch may defer a landing to full requalification rather than fabricate acceptance.
- [Nit] Canonical plan:20 still says the next step is the old coverage-preserving scope, while :417 supersedes dormant-only activation; :432 also names `load_local_device_config_diagnostic` rather than actual `load_device_config_diagnostic`. Refresh the near-top current-state pointer and correct that symbol during implementation without rewriting historical review records. These are navigation/name defects, not behavior blockers. No additional pre-existing blocking defect was found in the fully swept packet/plan; runtime inspection was bounded to the named seams, not a whole-repository audit.
- [Unverified — needs clone run] Strict ci resolution, @2 writer/reader, actual process binding, malicious/malformed receipt rejection, current @1 replay equality, end-to-end on/off selection and publication race behavior remain implementation/final-QA acceptance work. No validate.sh, test/*.sh, pytest, executable fixture, Git command, source edit or artifact edit was run in this reviewer turn. The blank Setup DoD was interpreted through packet lines8–23 and the canonical pivot/ordered acceptance sequence.

Evidence mode: Verify, with direct-source fallback. Graph list_projects found no index for this task checkout; nearest XYZ-forge index generation 2026-09-01T15:54:30Z is stale/foreign. search_graph returned no current wave implementation; check_index_coverage marked relevant sources changed/missing/not-tracked. Source reads, not that graph, support the findings.

Read-only probe commands (both exit 0; prefix each with `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`; scratch directory pre-created):

```python
# Executed through python3 - <<'PY'; publisher only imported, never main()/git().
import importlib.util, json, hashlib, pathlib
p=pathlib.Path("utils/py/hosted_lane_publish.py")
spec=importlib.util.spec_from_file_location("publisher",p)
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
root=pathlib.Path("TESTS-RESULTS/2026-10-15+GH-1076/disabled-profile")
o=json.loads((root/"publication-layout-observation.json").read_text())
paths=o["logical_future_layout"]
assert m.declared_paths(paths)==paths and m.receipt_paths(paths)==paths
rows=[json.loads(x) for x in (root/"proposed-validation-bundle.jsonl").read_text().splitlines()]
assert len(rows)==2
for row,fact in zip(rows,o["original_phase_facts"]):
    raw=row["telemetry_utf8"].encode("utf-8")
    assert row["phase"]==fact["phase"]
    assert hashlib.sha256(raw).hexdigest()==row["telemetry_sha256"]==fact["original_sha256"]
    events=[json.loads(x) for x in raw.splitlines()]
    start=[x for x in events if x.get("event")=="run.start"]
    assert len(start)==1 and start[0]["commit"]==o["source"]
    print(row["phase"],"bytes",len(raw),"run",start[0]["run"],"passed/total",fact["original_summary"]["passed"],fact["original_summary"]["total"])
assert m.receipt_targets([paths[0]])==([],[])
try:
    m.declared_paths([paths[0].replace("validation.jsonl","small.jsonl")])
except SystemExit:
    print("red control: separate small.jsonl rejected")
else:
    raise AssertionError("publisher admitted separate phase path")
print("PASS: two-row original-stream hashes and existing publisher path contract")
```

Decisive output:
```text
small bytes 23509 run f874fa8d4-47453 passed/total 75 75
skills-army-hq bytes 3146 run f874fa8d4-81198 passed/total 9 9
red control: separate small.jsonl rejected
PASS: two-row original-stream hashes and existing publisher path contract
```

```python
# Executed through python3 - <<'PY'; print existence/shape only, no config values.
import importlib.util, os, pathlib
s=importlib.util.spec_from_file_location("dc","utils/py/device_config.py")
d=importlib.util.module_from_spec(s); s.loader.exec_module(d)
p=pathlib.Path(d.get_device_config_path())
print("default_path_matches",str(p)==str(pathlib.Path.home()/".xyz/device_config.json"))
print("file_exists",p.is_file(),"is_symlink",p.is_symlink(),"path_override_set",bool(os.environ.get("XYZ_DEVICE_CONFIG_PATH")))
config,error=d.load_device_config_diagnostic()
print("ci_block_present","ci" in config,"load_error",error is not None)
```

Decisive output:
```text
default_path_matches True
file_exists True is_symlink False path_override_set False
ci_block_present False load_error False
```

Relay closed (Approved), no further reviewer turn needed. Handing the approved plan back to codex-producer for implementation and the separately authorized final QA; historical caps/receipts remain intact.


### Attestation · relay-drive — 2026-10-15T21:31:58Z
task: RELAY-GH1076-CONFIG-PIVOT-PLAN1
reviewer: codex
status: Approved
reviewed-head: 2c40a76fe4d7e6be60e0fbf18c1ce3f3901bd33c
added-range: 5470+8301
added-sha256: fc4e1fad79a8d496e04abcdfda607a1c9a2ac01a983707d18c1210be623bd16f
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
