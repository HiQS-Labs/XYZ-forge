"""Manual control of existing local receipt trust; not a CI case or software PASS."""
import json,sys,datetime
from pathlib import Path
sys.dont_write_bytecode=True
root=Path.cwd();sys.path.insert(0,str(root/'forge-gh1076-spike/utils/py'))
import gate_receipt
fixture=root/'gh1076-debug/local-receipt-trust-control'
sha='f1'*20
path=Path(gate_receipt.get_receipt_path(str(fixture),sha))
if path.exists():raise SystemExit('Preserve existing control; refusing overwrite')
path.parent.mkdir(parents=True)
record=dict(sha=sha,exit_code=0,gate='CONTROLLED fabricated claim: no suite executed',mode='sequential',WARNING='Manual trust-boundary control only; not software qualification')
path.write_text(json.dumps(record)+'\n');accepted,details=gate_receipt.check_receipt(str(fixture),sha)
record['exit_code']=1;path.write_text(json.dumps(record)+'\n');rejected,reason=gate_receipt.check_receipt(str(fixture),sha)
result=dict(kind='MANUAL TRUST-BOUNDARY CONTROL; no suites executed',at=datetime.datetime.now(datetime.timezone.utc).isoformat(),canonical_reader='utils/py/gate_receipt.py:check_receipt',synthetic_success_claim_accepted=accepted,failed_claim_accepted=rejected,failed_reason=reason,implication='Existing local reader is self-reported, not authenticated producer authority. This is documented behavior, not a new security defect.',limitations='Does not evaluate signed/hosted attestations or alter any source, gate, primary setting or CI case.')
(root/'gh1076-debug/premerge-trust-control.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
