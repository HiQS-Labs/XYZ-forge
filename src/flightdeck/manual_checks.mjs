// Manual experimental checks only; runs the same selector imported by app.js.
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {issueCards, laneIssues} from '../../web/flightdeck/issue-context.mjs';
const {snapshot, now} = JSON.parse(readFileSync(0, 'utf8'));
const repo = snapshot.repos.find(r => r.id === 'github.com/binoidcbd/ltvera-pandas');
assert.ok(repo && repo.issues.length && repo.lanes.length, 'nonempty fixture extraction');
const ids = value => issueCards(value, now).map(i => i.number).sort((a,b) => a-b);
assert.deepEqual(ids(repo), [83,332,390,421,440]);
// Isolate each attribution source so another source cannot mask a broken path.
const bare = {id: repo.id, issues: [], lanes: [], prs: [], events: []};
assert.deepEqual(ids({...bare, lanes: repo.lanes.filter(l => l.session_id === 'lane-440')}), [440]);
assert.deepEqual(ids({...bare, lanes: repo.lanes.filter(l => l.session_id === 'lane-many')}), [332,390,421]);
assert.deepEqual(laneIssues(repo.lanes.find(l => l.session_id === 'lane-review'), repo), [83]);
assert.deepEqual(ids({...bare, prs: repo.prs}), [83]);
const when = minutes => new Date(now - minutes*60000).toISOString();
const old = {...bare, issues: [{number:900,title:'Unrelated backlog',updated_at:when(2000)}]};
assert.deepEqual(ids(old), []);
const eventRepo = {...old, events:[{kind:'commit',issues:[450],occurred_at:when(10)}]};
assert.deepEqual(ids(eventRepo), [450]);
assert.deepEqual(ids({...bare, lanes:[{issues:[901],last_prompt_at:when(-20)}]}), []);
// A checker that has not caught a defect is not evidence: remove the only link.
assert.throws(() => assert.deepEqual(ids({...eventRepo,events:[]}), [450]), assert.AssertionError);
assert.throws(() => assert.deepEqual(ids({...bare, lanes:[{...repo.lanes[0],issue:null,issues:[],prs:[]}]}), [440]), assert.AssertionError);
console.log('manual UI selection: exact cards, isolated sources, stale/future exclusion, negative controls passed');
const closed = {...eventRepo, issues:[{number:450,state:'closed',updated_at:when(2)}]};
assert.deepEqual(ids(closed), [], 'closed work must not be revived by commit evidence');
assert.deepEqual(ids({...bare, lanes:[{issues:[460],last_prompt_at:when(90)}]}), [460], 'quiet work survives the hour cutoff');
assert.deepEqual(ids({...bare, lanes:[{issues:[461],last_prompt_at:when(1500)}]}), [], 'previous-day intent is not active today');
assert.deepEqual(ids({...bare, prs:[{number:500,state:'open',issues:[462,463],updated_at:when(2000)}]}), [462,463], 'old open PR preserves work across days');
assert.deepEqual(ids({...bare, prs:[{number:500,state:'closed',issues:[464],updated_at:when(2)}]}), []);
console.log('manual workday/lifecycle boundaries: 60m, midnight, closed work, carried PRs passed');

// Clock expiry and intent cannot fabricate attested progress.
const {snapshotFresh, progressTone} = await import('../../web/flightdeck/presentation.mjs');
const observed = when(1);
const healthSnapshot = {generated_at: observed, sources:[{id:'continuity', availability:'ok', coverage:'partial', observed_through:observed}]};
const progressRepo = {last_progress_at:when(10), events:[{source_ref:'continuity', occurred_at:when(10)}]};
assert.equal(progressTone(progressRepo, healthSnapshot, false, now), 'green');
assert.equal(progressTone({last_intent_at:observed}, healthSnapshot, false, now), 'unknown');
assert.equal(progressTone(progressRepo, healthSnapshot, true, now), 'unknown');
assert.equal(progressTone(progressRepo, healthSnapshot, false, now+360000), 'unknown');
assert.equal(snapshotFresh(healthSnapshot, now+360000), false);
const quiet = {...progressRepo,last_progress_at:when(130),events:[{source_ref:'continuity',occurred_at:when(130)}]};
assert.equal(progressTone(quiet, healthSnapshot, false, now), 'unknown');
assert.equal(progressTone(quiet, {...healthSnapshot,sources:[{...healthSnapshot.sources[0],coverage:'complete'}]}, false, now), 'unknown');
assert.throws(() => assert.equal(progressTone({last_intent_at:observed}, healthSnapshot, false, now), 'green'), assert.AssertionError);
console.log('manual display expiry: intent-only, partial coverage, failed GET and clock-only expiry passed');
