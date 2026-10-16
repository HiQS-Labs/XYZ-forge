# Continuation evidence and scope

The production diff against pinned development14081d61 is four files, +330/-37:
wave workflow +2/0, ci-route +43/-1, device_config +19/-2, wave_reconcile +266/-34.
The existing ci-route test only adapts its prior count expectation (+2/-2). No new CI case.
Governance/docs, review transcripts, native ledger integration and evidence are separate from that source count.

Both failed normal full gates remain authoritative failures. Targeted or simulated observations
below do not upgrade them, approve the source, qualify main, or activate the hosted workflow.
The supplemental final review remains FAIL1/1; its one Should was corrected by9e3e220c. No reset.

## Timeout diagnosis

The unchanged existing suite was compared with matched shell, executables, sanitized environment,
config override and actual nice10 priority. The first matched complete comparison passed9/9 on
both revisions. During a second comparison, a competing real gate and a host load burst were
observed; Codex fast passed on both, while an Agy whole-shim elapsed assertion failed on current.
A native subprocess observer then measured the original Codex cases at nice10: slow children
raised TimeoutExpired at1.003/1.006s with budget1; fast children returned in0.394s baseline and
0.287s current. Changed device_config/wave_reconcile modules were not loaded in that child path.
See timeout-matched-summary.json. Full diagnostic streams/config inventories remain local.

This disproves a deterministic three-Tick-commands-always-exceed1s explanation. It does not
retroactively identify the original failed child scheduling interval. No production correction
or test/deadline change is justified by these observations. Wait for host gate exclusivity, run
an uninstrumented existing-suite check at the same priority, then the normal gate if supported.

## Controlled @2 writer and publication recovery

controlled-v2-summary.json records actual production writer/reader/publisher calls in a retained
local Git fixture. The writer emitted @2 with two original fixture streams. A real local
non-fast-forward rejection was injected; publisher pushes returned false,true,true. It retained
receipts first, recomputed once with only-receipted/skip-pull and zero suite reruns, preserved the
racer's contribution, discarded stale transitions and kept receipt hashes identical. The current
production reader accepted the record; disabled mode and generic premerge validation rejected it.

Validation outcomes, metadata representing GitHub PR7 and recompute transitions are SIMULATED.
No registered suites, actual eligible GitHub PR, installation or live hosted recovery ran here.
This proves controlled producer/consumer/storage/recovery compatibility; it is not software
qualification or evidence of live activation. The original real f874 component runs remain
separate historical evidence. The live first-eligible-landing observation remains outstanding.

The 9KB controlled-v2-proof.tar.gz losslessly retains executed script, original record/container,
report and native publisher log. Archive-member hashes are in controlled-v2-summary.json. The
complete fixture and all unique discarded-commit refs remain local; no unique artifact was deleted.

## Evidence audit and duplicate compaction

The changed evidence initially comprised142 files/4.13MB. Known credential/private-key/token/URL
patterns found no matches, including the four decompressed hosted logs. This is not a guarantee
against arbitrary formats. Artifacts contain workstation paths and tool/package metadata; full
new environment and timing dumps remain local rather than entering the proposed PR.

The exact duplicate empty API responses describe different endpoints, so both are retained.
The two original streams intentionally also occur inside the proposed two-row container; that
copy is the byte-retention experiment, not another run. Other historical versions repeat facts
while preserving changed hypotheses and their failures. See source-evidence-audit.json.

The current220-record compatibility report repeated all218 earlier records in order plus two
new records. It is now a59-line lossless delta rather than a5208-line duplicate. Its original
raw bytes are preserved locally and in Git blob57e94100f5ec0fe15c33994d3d3e2a04efc22d38.
No history was rewritten. compatibility-compaction.json records hashes. Reconstruction:

```python
import hashlib,json,pathlib
p=pathlib.Path('TESTS-RESULTS/2026-10-15+GH-1076/config-pivot/historical-receipt-compatibility.json')
d=json.loads(p.read_text());base=(p.parent/d['base_report']).read_bytes()
assert hashlib.sha256(base).hexdigest()==d['base_sha256']
rows=json.loads(base)['records']
for x in d['record_insertions']: rows.insert(x['at'],x['record'])
full={k:rows if k=='records' else d['metadata'][k] for k in d['key_order']}
raw=(json.dumps(full,indent=2)+'\n').encode()
assert hashlib.sha256(raw).hexdigest()==d['original_sha256']
```

Necessary original gate telemetry and failures remain committed. Future diagnostic raw streams
are preserved locally; concise observations and compressed controlled proof keep the proposed
diff smaller without deleting unique evidence or resetting review history.

After the competing gate completed, the complete original suite was run uninstrumented at
nice10 with the same sanitized controls on current then baseline. Both passed9/9 with clean
identities; wall13.304/13.428s, one-minute loads approximately9–11. This supports one normal
conditioned full attempt; it neither upgrades old failed runs nor proves their exact origin.

Development subsequently advanced to PR1053 merge d48aa774. Integration52c59c5f preserves both
CHANGELOG sections and12 ours-changed/9 incoming-changed INSERT rows, no missing rows, generation
floor1671, using the native rebuild/check. Incoming generated view retained. The source-only
production diff remains +330/-37 across four files against that current base.
