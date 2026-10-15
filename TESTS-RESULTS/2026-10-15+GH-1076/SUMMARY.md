# GH1076 verification and handoff

Safe policy/consumer work is independently reviewed (plan2/3, final2/3). Original PARKED/FAIL
results and corrective manual controls are retained. Ten existing focused suites passed; after the
parser correction, the three affected existing receipt/reconciliation suites passed again with
unchanged repository identity. No CI test/assertion/parameter/registry/workflow was changed.

Matched before: f974fcee15647aae6551fcc81b129f5a6127120b, normal ./validate.sh balanced4,
409/409, rc0,1090.831s inner runner wall,1091.305s outer wall, no retries; identity unchanged.
Two suites printed three skip lines total (ci-workflow1,marathon-plan2); these are omissions,
not newly passed coverage.21 Python-layer tests passed. Failed MAX-contaminated calibration
remains separate:408/409,rc1,1455.101s runner wall, all three initial failures/retries retained.

Final full normal push gate passed409/409 atd1ca36b5bac1a3f208f6392908c4496f5fd77ab2,
no retries,911.376s inner runner wall; actual push rc0,916.015s outer wall including hook/network.
Remote branch readback equals that exact tested SHA. Source/config/origin/worktree stable; only
expected pushed tracking-ref and its symbolic origin/HEAD alias resolved to the pushed commit.
The one-off wrapper returned97 because its allowlist omitted the alias. Original false flags/97
remain retained; after-identity-adjudication.json proves exact allowed ref delta/reflog and stable
source identity. This is not a repaired/overridden suite result or hidden rerun.

Before1090.831s versus after911.376s:179.455s lower(16.45%) in this single observed pair.
No speedup/savings claim: start load104.49/151.91/193.76 versus22.78/73.55/110.61, caches
uncontrolled, intended task plus already-landed PR1078 docs/reconciliation differ. Tool versions,
full runner/hook/workflow source, full registry and normal4workers match; no thermal warning.

Runner counted three skip lines in two suites in both. In addition, the existing live relay probe
was explicitly skipped by RELAY_SELF_SUFFICIENCY_SKIP=1 in both, despite its telemetry skip_lines=0.
Thus the numeric skip counter is not an exhaustive omission inventory. Operator-retired suites
remain outside the registry.21Python-layer tests passed in each run.

Draft PR and actual exact-head hosted outcomes remain pending. No natural exact-f974 hosted CI
run exists for equivalent before/after comparison; no workflow was dispatched/rerun.
Subsequent evidence-only updates to this summary will report actual outcomes without changing
source. Local parallel self-checks do not qualify development/main on hosted macOS.

All20 historical failed logs reviewed (v2); no eligible mapped-Medium failure/change pair proved.
Medium stays full. Missing eligible scope/causality, consumer+non-shell coverage, expected selection
replay, receipt and workflow/protection compatibility retain full. Batch authority remains unready
pending separately owned PR1069/GH1072/GH1073 and complete freeze/identity/invalidation evidence.
No batch activation, merge, deployment or cleanup is authorized by this handoff.
