// Real browser regression, no npm dependency and no live/private data.
// Requires an installed Chromium/Chrome via BROWSER_EXECUTABLE (macOS default).
import assert from 'node:assert/strict';
import {createServer} from 'node:http';
import {readFile, mkdtemp} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join, resolve} from 'node:path';
import {spawn} from 'node:child_process';
import {once} from 'node:events';
const root = resolve(import.meta.dirname, '../..');
let failed = false;
const at = new Date().toISOString();
const old = new Date(Date.now() - 604800000).toISOString();
const issue = {number:7,title:'Quiet fixture',state:'open',labels:['in-progress'],native_identity_valid:true,
  fetched_at:at,updated_at:old,work_evidence:[{supported:true,roots_complete:true,status_label:'in-progress',read_at:at,
    start:{at:old,event:'in_flight',freshness:'stale'},lifecycle:{at:old,event:'in_flight'}}]};
const snapshot = {schema_version:1,generated_at:at,coverage:'partial',sources:[],repos:[
  {id:'github.com/example/project',name:'Fixture',issues:[issue],prs:[],lanes:[],events:[],source_refs:[]}]};
const server = createServer(async (req,res) => {
  if (req.url === '/flightdeck.json') {
    res.writeHead(failed ? 503 : 200, {'Content-Type':'application/json'});
    return res.end(JSON.stringify(snapshot));
  }
  const name = req.url.split('?')[0] === '/' ? 'index.html' : req.url.split('?')[0].slice(1);
  if (!/^[\w.-]+$/.test(name)) {res.writeHead(404);return res.end();}
  try {
    const bytes = await readFile(join(root,'web/flightdeck',name));
    res.writeHead(200, {'Content-Type':name.endsWith('.js') || name.endsWith('.mjs') ? 'text/javascript' : name.endsWith('.css') ? 'text/css' : 'text/html'});
    res.end(bytes);
  } catch {res.writeHead(404);res.end();}
});
server.listen(0,'127.0.0.1'); await once(server,'listening');
const profile = await mkdtemp(join(tmpdir(),'flightdeck-browser-'));
const chrome = spawn(process.env.BROWSER_EXECUTABLE || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', [
  '--headless', '--no-first-run', '--no-default-browser-check', '--disable-background-networking',
  '--disable-component-update', '--disable-sync', '--disable-default-apps', '--use-mock-keychain',
  '--disable-features=OptimizationHints,MediaRouter', '--remote-debugging-address=127.0.0.1',
  '--remote-debugging-port=0', `--user-data-dir=${profile}`, 'about:blank'], {stdio:['ignore','ignore','pipe']});
let socket;
try {
  const endpoint = await new Promise((accept,reject) => {
    let text = '';
    const timeout = setTimeout(() => reject(Error('browser startup timeout')),10000);
    chrome.once('error', error => {clearTimeout(timeout);reject(error);});
    chrome.stderr.on('data', bytes => {
      text += bytes;
      const match = text.match(/DevTools listening on (ws:\/\/[^\s]+)/);
      if (match) {clearTimeout(timeout);accept(match[1]);}
    });
  });
  socket = new WebSocket(endpoint); await once(socket,'open');
  let id = 0; const pending = new Map();
  socket.addEventListener('message', ({data}) => {
    const message = JSON.parse(data); const request = pending.get(message.id);
    if (request) {pending.delete(message.id);message.error ? request.reject(Error(message.error.message)) : request.accept(message.result);}
  });
  const call = (method,params={},sessionId) => new Promise((accept,reject) => {
    const request = ++id;
    const timer = setTimeout(() => {pending.delete(request);reject(Error('CDP timeout'));},5000);
    pending.set(request,{accept:value=>{clearTimeout(timer);accept(value);},reject:error=>{clearTimeout(timer);reject(error);}});
    socket.send(JSON.stringify({id:request,method,params,...(sessionId ? {sessionId} : {})}));
  });
  const target = await call('Target.createTarget',{url:'about:blank'});
  const {sessionId} = await call('Target.attachToTarget',{targetId:target.targetId,flatten:true});
  await call('Page.enable',{},sessionId);
  await call('Page.addScriptToEvaluateOnNewDocument',{source:"window.__clockRenders=[]; const original=setInterval; window.setInterval=(callback,ms,...args)=>{if(ms===60000) __clockRenders.push(callback);return original(callback,ms,...args);};"},sessionId);
  await call('Page.navigate',{url:`http://127.0.0.1:${server.address().port}/?view=c&repo=github.com/example/project`},sessionId);
  const evaluate = async expression => {
    const value = await call('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true},sessionId);
    if (value.exceptionDetails) throw Error(value.exceptionDetails.exception?.description || value.exceptionDetails.text);
    return value.result.value;
  };
  for (let tries=0; tries<50; tries++) {
    if (await evaluate("document.querySelector('[data-issue=\"7\"] .details') !== null")) break;
    await new Promise(accept=>setTimeout(accept,100));
  }
  assert.equal(await evaluate("document.querySelector('[data-issue=\"7\"] .repo-summary').textContent.includes('In progress')"),true);
  const open = () => evaluate("document.querySelector('[data-issue=\"7\"] .details').click(); document.querySelector('#detail').open");
  assert.equal(await open(),true);
  assert.match(await evaluate("document.querySelector('#detail textarea').value"), /In progress/);
  const handoffBefore = await evaluate("document.querySelector('#detail textarea').value");
  await evaluate("window.__clockRenders[0]()");
  assert.equal(await evaluate("document.querySelector('#detail').open"),true);
  assert.equal(await evaluate("document.querySelector('#detail textarea').value"),handoffBefore);
  const refresh = async () => {
    await evaluate("document.querySelector('#retry').click()");
    // Wait for this fixture's asynchronous fetch/render, not a clock-only tick.
    for (let tries=0; tries<50; tries++) {
      if (!await evaluate("document.querySelector('#detail').open")) return;
      await new Promise(accept=>setTimeout(accept,100));
    }
    assert.fail('changed handoff stayed open');
  };
  snapshot.repos[0].lanes = [{issues:[7],agent:'Fixture agent',task:'A changed next step',last_prompt_at:at}];
  await refresh();
  assert.equal(await open(),true);
  assert.match(await evaluate("document.querySelector('#detail textarea').value"), /A changed next step/);
  issue.labels = [];
  await refresh();
  assert.equal(await open(),true);
  assert.match(await evaluate("document.querySelector('#detail textarea').value"), /Label mismatch/);
  issue.labels = ['in-progress'];
  await refresh();
  assert.equal(await open(),true);
  // Inferred cards remain valid targets without a native cached issue row.
  snapshot.repos[0].lanes.push({issues:[8],task:'Intent-only task',last_prompt_at:at});
  await evaluate("document.querySelector('#detail').close(); document.querySelector('#retry').click()");
  for (let tries=0; tries<50; tries++) {
    if (await evaluate("document.querySelector('[data-issue=\"8\"] .details') !== null")) break;
    await new Promise(accept=>setTimeout(accept,100));
  }
  await evaluate("document.querySelector('[data-issue=\"8\"] .details').click(); window.__clockRenders[0]()");
  assert.equal(await evaluate("document.querySelector('#detail').open"),true);
  snapshot.repos[0].lanes.pop();
  await refresh();
  assert.equal(await open(),true);
  // Force the real fetch failure, keeping the drawer open during the transition.
  failed = true;
  await evaluate("document.querySelector('#retry').click()");
  for (let tries=0; tries<50; tries++) {
    if (!await evaluate("document.querySelector('#detail').open")) break;
    await new Promise(accept=>setTimeout(accept,100));
  }
  assert.equal(await evaluate("document.querySelector('#detail').open"),false);
  assert.equal(await open(),true);
  assert.match(await evaluate("document.querySelector('#detail textarea').value"), /Read unavailable/);
  // Recover, reopen, and advance only the browser clock. Capture the existing
  // real 60-second render callback instead of waiting five minutes.
  failed = false;
  await evaluate("document.querySelector('#detail').close(); document.querySelector('#retry').click()");
  for (let tries=0; tries<50; tries++) {
    if (await evaluate("document.querySelector('[data-issue=\"7\"] .repo-summary').textContent.includes('In progress')")) break;
    await new Promise(accept=>setTimeout(accept,100));
  }
  assert.equal(await open(),true);
  await evaluate("Date.now = () => " + (Date.now()+301000));
  // No fetch or data change: execute the captured production clock-only tick.
  await evaluate("window.__clockRenders[0]()");
  for (let tries=0; tries<50; tries++) {
    if (!await evaluate("document.querySelector('#detail').open")) break;
    await new Promise(accept=>setTimeout(accept,100));
  }
  assert.equal(await evaluate("document.querySelector('#detail').open"),false);
  assert.equal(await open(),true);
  assert.match(await evaluate("document.querySelector('#detail textarea').value"), /Read unavailable/);
  console.log('real Chrome: unchanged/inferred drawers preserved; context/status/missing target/failure/expiry invalidate handoffs');
} finally {
  socket?.close(); chrome.kill('SIGKILL'); await once(chrome,'exit').catch(()=>{}); server.close();
  // Chrome-created disposable profile stays outside Git; no source cleanup.
}
