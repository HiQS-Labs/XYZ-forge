import assert from 'node:assert/strict';
import {issueStatus, issueCards, laneIssues} from '../../web/flightdeck/issue-context.mjs';
import {sourceStatus, PROGRESS_HELP} from '../../web/flightdeck/presentation.mjs';
const now = Date.parse('2026-09-17T20:00:00Z');
const time = age => new Date(now - age * 1000).toISOString();
const evidence = {id:'opaque-root', supported:true, read_at:time(5), status_label:'in-progress',
  start:{at:time(604800),event:'in_flight',freshness:'stale'}, lifecycle:{at:time(604800),event:'in_flight'}};
const active = {number:7,title:'Quiet established work',state:'open',native_identity_valid:true,
  labels:['in-progress'],fetched_at:time(60),updated_at:time(604800),work_evidence:[evidence]};
assert.equal(issueStatus(active, now).kind, 'in-progress');
assert.equal(issueCards({issues:[active,{...active,number:8}]},now).length, 2);
assert.match(issueStatus(active, now).reason,/old start/);
const closed = {...active,state:'closed',state_reason:'completed'};
assert.equal(issueStatus(closed,now).label,'Completed');
assert.match(issueStatus(closed,now).reason,/cleanup pending/);
assert.equal(issueStatus({...closed,state_reason:'not_planned'},now).label,'Cancelled');
assert.equal(issueCards({issues:[closed]},now)[0].workflow.kind,'closed');
for (const label of [null, 'in-progress']) {
  for (const reason of ['completed', 'not_planned']) {
    const stopped = {...closed, labels:[], state_reason:reason,
      work_evidence:[{...evidence,status_label:label,start:null,lifecycle:{at:time(20),event:'completed'}}]};
    assert.equal(issueCards({issues:[stopped]},now)[0].workflow.label, reason === 'completed' ? 'Completed' : 'Cancelled');
  }
}
assert.equal(issueStatus({...active,work_evidence:[{...evidence,roots_complete:false}]},now).kind,'unknown');
assert.equal(issueStatus({...closed,work_evidence:[{...evidence,roots_complete:false}]},now).kind,'closed');
assert.equal(issueStatus({...active,fetched_at:time(7201)},now).kind,'unknown');
assert.equal(issueStatus({...active,fetched_at:time(-1)},now).kind,'unknown');
assert.equal(issueStatus({...active,fetched_at:'2026-09-17T20:00:00'},now).kind,'unknown');
assert.equal(issueStatus({...active,native_identity_valid:false},now).kind,'unknown');
assert.equal(issueStatus({...active,native_conflict:true},now).kind,'unknown');
assert.equal(issueStatus({...closed,native_conflict:true},now).kind,'unknown');
assert.equal(issueStatus(active,now,false).kind,'unknown');
assert.equal(issueStatus({...active,labels:[]},now).kind,'conflict');
assert.equal(issueStatus({...active,work_evidence:[]},now).kind,'unknown');
assert.equal(issueStatus({...active,work_evidence:[{...evidence,start:null}]},now).kind,'unknown');
assert.equal(issueStatus({...active,work_evidence:[{...evidence,supported:false}]},now).kind,'unknown');
assert.equal(issueStatus({...active,work_evidence:[{...evidence,read_at:time(301)}]},now).kind,'unknown');
assert.equal(issueStatus({...active,labels:[],work_evidence:[{...evidence,status_label:null,start:null}]},now).kind,'context');
const duplicate = {...active,work_evidence:[evidence,{...evidence,status_label:null,start:null}]};
const marker = {...evidence,error:'unqualified-ledger-row',status_label:null,start:null,lifecycle:null};
const unqualified = {...active,updated_at:time(604800),work_evidence:[marker]};
assert.equal(issueCards({issues:[unqualified]},now)[0].workflow.kind,'unknown');
assert.equal(issueStatus({...active,work_evidence:[evidence,marker]},now).kind,'unknown');
assert.equal(issueStatus({...closed,work_evidence:[marker]},now).kind,'closed');
assert.equal(issueStatus(duplicate,now).kind,'conflict');
assert.deepEqual(issueStatus(duplicate,now), issueStatus({...duplicate,work_evidence:[...duplicate.work_evidence].reverse()},now));
const repo = {prs:[{number:7,issues:[99]}]};
assert.deepEqual(laneIssues({issues:[7]},repo),[7]);
assert.deepEqual(laneIssues({prs:[7]},repo),[99]);
assert.equal(issueStatus(active,now).kind,'in-progress','open issue is not completed by a merged PR');
// GH-797: unknown/unconfigured sources are grey with an enable hint; only read failures are red.
const src = (id, availability, extra = {}) => ({id, availability, coverage:'unknown', observed_through:null, error:null, ...extra});
assert.equal(sourceStatus(src('xyz_work','disabled')).tone,'off');
assert.match(sourceStatus(src('xyz_work','disabled')).help,/FLIGHTDECK_XYZ_ROOTS.*add xyz_work to it/);
assert.match(sourceStatus(src('clio','disabled')).help,/FLIGHTDECK_CONNECTORS/);
assert.deepEqual([sourceStatus(src('topology','unavailable')).tone, sourceStatus(src('topology','unavailable')).label],['off','not set up']);
assert.match(sourceStatus(src('continuity','unavailable')).help,/no producer.*FLIGHTDECK_CONTINUITY_JSON/);
assert.equal(sourceStatus(src('rebalance','unavailable',{error:'FileNotFoundError'})).tone,'failed');
assert.match(sourceStatus(src('rebalance','unavailable',{error:'FileNotFoundError'})).help,/FileNotFoundError.*FLIGHTDECK_REBALANCE_DB/);
assert.equal(sourceStatus(src('xyz_work','unavailable',{roots:[{error:'ledger-locked'}]})).tone,'failed','root error is a read failure');
assert.equal(sourceStatus(src('clio','ok',{coverage:'partial'})).tone,'ok');
const mixed = src('xyz_work','ok',{error:'source-unavailable-or-unsupported',roots:[{supported:true,error:null},{supported:false,error:'ledger-locked'}]});
assert.equal(sourceStatus(mixed).tone,'failed','a failed xyz_work root is red even when another root read');
assert.match(sourceStatus(mixed).help,/ledger-locked/);
const capped = src('xyz_work','ok',{error:'issue-cap',roots:[{supported:true,error:null}]});
assert.equal(sourceStatus(capped).tone,'partial','a cap warning is not a read failure');
assert.equal(sourceStatus({...mixed,error:null,roots:[{supported:true,error:null}]}).tone,'ok');
assert.equal(sourceStatus(mixed,false).tone,'stale');
assert.equal(sourceStatus(src('clio','unavailable',{error:'X'}), false).tone,'stale');
assert.match(PROGRESS_HELP,/Not an error/);
console.log('work-status production selector: nonempty agreement, quiet work, closure, uncertainty, identity and typed references passed');
