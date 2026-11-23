# GH-1243 manual evidence

Codex now writes its final message to `<label>.codex.md` using
`--output-last-message`; combined stdout/stderr is retained separately in
`<label>.codex.md.transcript`. Attestation applies only to that diagnostic transcript.
Idle monitoring and timeout partial surfacing use the diagnostic stream. Validation,
citation screening, provenance classification and blind payloads use the final message.
Missing or empty final messages fail even when diagnostics contain text.

## Observed controls

The baseline neutralizer retained `TRANSCRIPT_SENTINEL` and `exec log` from the
combined transcript, demonstrating the answer-only requirement fails on that input.
The final CLI-shaped fixture printed that same diagnostic transcript and wrote only
`[Pass] utils/py/consult.py:89 final answer.` to the requested last-message path.
The neutral answer matched that single line exactly; the raw diagnostic sentinel
remained available separately. Cited-final screening returned false (no warning),
uncited-final screening returned true, and missing/empty finals were rejected.
The Python source parsed successfully. All 11 manual assertions passed.
Source digest and actual values are retained in provenance.jsonl.

## Reproduction

Run from the repository root with bytecode disabled. This is a manual fixture check,
not a new suite or gate. Its scratch files belong only in `.relay-scratch/`.

```python
import ast, hashlib, json, os, pathlib, sys
sys.path.insert(0, 'utils/py')
import consult
root=pathlib.Path('.relay-scratch').resolve()
answer='[Pass] utils/py/consult.py:89 final answer.\n'
raw='model: gpt-stub\nprovider: mock\nsandbox: test\nPrompt echo [Pass]\nTRANSCRIPT_SENTINEL\nexec log\ntokens used\n123\n'+answer
results=[]
def check(name, value, expected=True):
    results.append({'check':name,'observed':value,'expected':expected,'pass':value==expected})
    assert value==expected, name
check('baseline transcript leaks sentinel', 'TRANSCRIPT_SENTINEL' in consult._neutralize_answer_text(raw,'advisor.md','A','codex'))
# Exercise the actual launcher with a CLI-shaped fixture that honors the final-message flag.
stub=root/'advisor.py'
stub.write_text('import pathlib,sys\na=sys.argv\npathlib.Path(a[a.index("--output-last-message")+1]).write_text('+repr(answer)+')\nprint('+repr(raw)+')\n')
out=root/'advisor.md'; transcript=str(out)+'.transcript'
proc=consult.guarded_with_timeout([sys.executable,str(stub),'exec','--output-last-message',str(out)],str(root),transcript,10)
proc.wait(timeout=10)
check('fixture exit',proc.returncode,0)
check('nonempty final',out.stat().st_size>0)
check('raw diagnostics retained', 'TRANSCRIPT_SENTINEL' in pathlib.Path(transcript).read_text())
check('cited final not stamped',consult.rtl_has_uncited_claim(str(out)),False)
consult.write_neutral_payloads(str(root),'paired',[('codex',str(out),True)])
neutral=(root/'answer-A.md').read_text()
check('neutral answer only',neutral,answer)
out.write_text('[Pass] no evidence\n')
check('uncited final stamped',consult.rtl_has_uncited_claim(str(out)))
# Nonempty CLI output cannot rescue a missing/empty last-message file.
missing=root/'missing.md'
check('missing final rejected',consult.advisor_answer_ok(str(missing),'codex'),False)
out.write_text('')
check('empty final rejected',consult.advisor_answer_ok(str(out),'codex'),False)
source=pathlib.Path('utils/py/consult.py').read_text(); ast.parse(source)
check('launch wired to final-message flag','["--output-last-message", f_out, full_prompt]' in source)
check('launch diagnostics separate','guarded_with_timeout(cmd, wt, f_out + ".transcript", timeout_s, cenv)' in source)
record={'command':'PYTHONDONTWRITEBYTECODE=1 python3 .relay-scratch/check_payload.py','source_sha256':hashlib.sha256(source.encode()).hexdigest(),'results':results,'limitations':'Manual CLI fixture, not live providers or existing shell suites; harness verification pending.'}
(root/'result.json').write_text(json.dumps(record,indent=2)+'\n')
print(json.dumps(record,indent=2))
```

## Limits and handoff

No shell suites or full gates were run in this linked worktree. The harness owns
that verification. No live Codex + agy request was made, so comparable live answer
shape/size remains pending. This manual control proves the output boundary with a
CLI fixture, not provider behavior.

`test/synthetic/gh101-consult-programmatic.sh` now supplies a last-message file in
its Codex fixture and emits a separate diagnostic sentinel. `test/consult.sh`
contains stdout-only Codex stubs that do not implement `--output-last-message`;
these need adapting before that suite can qualify the new strict contract. That
file is outside this turn's edit allowlist. Do not weaken missing-final safety to
make those obsolete fixtures pass. No readiness or full-gate claim is made here.

## Independent review disposition and bounded fixture repair

Original agy ChangesRequested is retained in RELAY.md. Fresh independent round2 replayed actual consult.main against baseline56b5b89b and candidate09027b1d: baseline leaks sentinel/false citation warning; candidate preserves cited final text, separates diagnostics, still warns on uncited answers, and rejects missing/empty last messages with exit5. The helper-level admission probe is a false negative for this valid caller-boundary fix. The reviewed replacement exercises the public CLI with a controlled advisor fixture, no provider call.

Existing stdout-only fixtures in consult, gh308-consult-guards, gh589-consult-no-tick and archive-writers now honor --output-last-message while preserving stdout for the Bash fallback. The gh308 raw-attestation assertion follows .codex.md.transcript. No runtime fallback or missing-final weakening. This is one manual fixture/probe repair after one engine builder, not a second automated delivery; model-builder history remains1, prior queue attempts preserved. Fresh final review and qualification remain required. No live-provider consult claimed.
