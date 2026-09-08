'use strict';
const carousel=document.getElementById('carousel');
const params=new URLSearchParams(location.search);
const issueMode=document.body.dataset.view==='issues';
const parentRepo=issueMode?repos.find(r=>r.id===(params.get('repo')||'ltvera')):null;
// Group by issue while retaining original lane indices for event and PR attribution.
function issueViews(repo){
  if(!repo)return [];
  return [...new Set(repo.lanes.map(l=>l.issue))].map(issue=>{
    const lanes=repo.lanes.map((l,i)=>({...l,sourceLane:i})).filter(l=>l.issue===issue);
    return {...repo,id:repo.id+'-'+issue,sourceId:repo.id,issue,name:lanes[0].task,lanes,
      prs:repo.prs===null?null:repo.prs.filter(p=>lanes.some(l=>l.sourceLane===p.lane))};
  });
}
const viewRepos=issueMode?issueViews(parentRepo):repos;
const loadedAt=Date.now(),initialMinute=942;
let demoOffset=0;
const minuteNow=()=>initialMinute+Math.floor((Date.now()-loadedAt)/60000)+demoOffset;
const progressAge=l=>l.age===null?null:l.age+minuteNow()-initialMinute;
const ageLabel=n=>n===null?'unknown':n<60?`${n}m`:`${Math.floor(n/60)}h ${String(n%60).padStart(2,'0')}m`;
const timeLabel=n=>`${String(Math.floor(n/60)%24).padStart(2,'0')}:${String(n%60).padStart(2,'0')}`;
function repoEvents(r,now=minuteNow()){
  return progressEvents.filter(e=>e.repo===(r.sourceId||r.id)).map(e=>{
    const lane=r.sourceId?r.lanes.findIndex(l=>l.sourceLane===e.lane):e.lane;
    const laneInfo=r.lanes[lane];
    return laneInfo?{...e,lane,laneInfo,at:initialMinute-laneInfo.age}:null;
  }).filter(e=>e&&!e.laneInfo.unknown&&e.laneInfo.age!==null&&now-e.at>=0&&now-e.at<60).sort((a,b)=>b.at-a.at);
}
function activeIssues(events){return [...new Map(events.map(e=>[e.laneInfo.issue,e])).values()];}
function health(r){const known=r.lanes.filter(l=>!l.unknown&&l.age!==null);const waiting=known.filter(l=>progressAge(l)>=120),checkIn=known.filter(l=>progressAge(l)>=60&&progressAge(l)<120);const unknown=r.lanes.some(l=>l.unknown||l.age===null);const latest=known.length?Math.min(...known.map(progressAge)):null;return {waiting,checkIn,unknown,latest,color:waiting.length?'red':checkIn.length?'amber':unknown?'gray':'green',label:waiting.length?`${waiting.length} waiting lane${waiting.length===1?'':'s'}`:checkIn.length?`${checkIn.length} lane${checkIn.length===1?'':'s'} to check in`:unknown?'Progress signal unknown':'Recent progress'};}
function bars(r,events){const buckets=Array.from({length:12},(_,i)=>events.filter(e=>Math.floor((minuteNow()-e.at)/5)===11-i).length);return `<div class="activity-bars" role="img" aria-label="${events.length} recorded updates in the last hour; bars represent five-minute intervals">${buckets.map(n=>`<i class="${n?'has-event':''}" style="height:${n?Math.min(24,10+n*7):5}px"></i>`).join('')}</div><div class="bar-labels"><span>−60m</span><span>−30m</span><span>now</span></div>`;}
function activityMarkup(r,events){if(!events.length)return `<div class="no-events"><b>${health(r).unknown?'Activity unavailable':'No recorded progress in this hour'}</b>${health(r).unknown?'The last-hour feed is missing. This is not evidence of inactivity.':'This repo stays in view so a quiet lane does not get forgotten.'}</div>`;return `<div class="timeline">${events.map(e=>`<div class="event"><time class="mono">${timeLabel(e.at)}</time><span class="event-rail"><i class="dot"></i></span><div><p class="event-text">${esc(e.text)}</p><p class="event-meta">${e.laneInfo.agent} · ${ageLabel(minuteNow()-e.at)} ago</p></div></div>`).join('')}</div>`;}
function issueMarkup(r,events){const issues=activeIssues(events);return `<div class="section-title"><h2>Issues active this hour</h2><span>${health(r).unknown&&!events.length?'Unknown':issues.length+' linked'}</span></div>${issues.length?issues.map(e=>`<div class="issue"><span class="issue-number mono">#${e.laneInfo.issue}</span><div><strong>${esc(e.laneInfo.task)}</strong><p>${e.laneInfo.agent} · ${esc(e.laneInfo.basis)}</p></div></div>`).join(''):`<p class="empty-issues">${health(r).unknown?'Issue activity cannot be confirmed.':'No issues with recorded progress in this hour.'}</p>`}`;}
function waitingMarkup(r){const recentLanes=new Set(repoEvents(r).map(e=>e.lane));return r.lanes.filter((l,i)=>!recentLanes.has(i)).map(l=>{const age=progressAge(l),unknown=l.unknown||age===null,tone=unknown?'gray':age>=120?'red':age>=60?'amber':'gray';const label=unknown?'Last-known context · progress unknown':age>=120?'Still waiting · '+ageLabel(age):age>=60?'Check in · '+ageLabel(age):'Context only · no recorded event';return `<div class="attention context-${tone}"><div class="attention-top"><i class="dot"></i>${label}</div><p>${l.agent} · ${esc(l.task)}<br><span class="context-issue">${unknown?'Unconfirmed issue association':age>=60?'Outside the last hour':'No event recorded this hour'} · #${l.issue}</span><br>${esc(l.next.replace(/^Review Review /,'Review '))}</p></div>`;}).join('');}
function card(r,index){if(issueMode)return issueCard(r,index);const h=health(r),events=repoEvents(r),prs=r.prs||[],ready=prs.filter(p=>p.state==='ready').length,qa=prs.filter(p=>p.state==='qa').length;return `<article class="card ${h.waiting.length?'has-waiting':''} ${h.unknown?'is-unknown':''}" data-repo="${r.id}" style="--repo-color:${r.color}" aria-labelledby="title-${r.id}"><div class="card-scroll"><div class="card-top"><span>Flightdeck / Focus</span><span class="position mono">${String(index+1).padStart(2,'0')} / 07</span></div><div class="repo-heading"><span class="repo-mark">${r.initials}</span><h1 id="title-${r.id}"><button class="focus-toggle" type="button" aria-label="Spotlight ${r.name}" aria-pressed="false">${r.name}</button></h1></div><p class="intent">${r.goal}</p><div class="health ${h.color}"><i class="dot"></i><span class="health-label">${h.label}</span><span class="latest-label">${h.latest===null?'No observation':'Latest '+ageLabel(h.latest)+' ago'}</span></div><div class="counts"><div class="count"><b>${String(r.clones.length).padStart(2,'0')}</b><span>full clones</span></div><div class="count"><b>${String(r.worktrees.length).padStart(2,'0')}</b><span>worktrees</span></div><div class="count"><b>${String(r.lanes.length).padStart(2,'0')}</b><span>agent lanes</span></div></div><section class="hour"><div class="section-title"><h2>Last hour</h2><span class="event-total">${h.unknown&&!events.length?'Data missing':events.length+' update'+(events.length===1?'':'s')}</span></div><p class="window mono">${timeLabel(minuteNow()-60)} — ${timeLabel(minuteNow())} PDT</p><div class="bars">${bars(r,events)}</div><div class="events">${activityMarkup(r,events)}</div></section><section class="issues">${issueMarkup(r,events)}</section><div class="waiting">${waitingMarkup(r)}</div><section class="checkout-names"><div class="section-title"><h2>Where the work lives</h2><span>${r.clones.length+r.worktrees.length} folders</span></div>${r.clones.map(n=>`<div class="folder">${icon('folder')}<span class="folder-name mono" title="${esc(n)}">${esc(n)}</span><span class="folder-type">CLONE</span></div>`).join('')}${r.worktrees.map(n=>`<div class="folder">${icon('folder')}<span class="folder-name mono" title="${esc(n)}">${esc(n)}</span><span class="folder-type">WORKTREE</span></div>`).join('')}</section></div><footer class="card-footer"><span class="pr-summary">${icon('pr')}${r.prs?`${ready} merge ready · ${qa} need QA`:'PR inventory unknown'}</span><span class="sample">LAYOUT B · SAMPLE DATA</span></footer></article>`;}
function updateActivity(){viewRepos.forEach(r=>{const el=carousel.querySelector(`[data-repo="${r.id}"]`),events=repoEvents(r),h=health(r);el.classList.toggle('has-waiting',h.waiting.length>0);el.querySelector('.health').className='health '+h.color;el.querySelector('.health-label').textContent=h.label;el.querySelector('.latest-label').textContent=h.latest===null?'No observation':'Latest '+ageLabel(h.latest)+' ago';el.querySelector('.event-total').textContent=h.unknown&&!events.length?'Data missing':events.length+' update'+(events.length===1?'':'s');el.querySelector('.window').textContent=`${timeLabel(minuteNow()-60)} — ${timeLabel(minuteNow())} PDT`;el.querySelector('.bars').innerHTML=bars(r,events);el.querySelector('.events').innerHTML=activityMarkup(r,events);el.querySelector('.issues').innerHTML=issueMode?agentMarkup(r):issueMarkup(r,events);el.querySelector('.waiting').innerHTML=waitingMarkup(r);if(issueMode)el.querySelector('.count:nth-child(2) b').textContent=h.unknown&&!events.length?'—':events.length;});}
function agentMarkup(r){return `<div class="section-title"><h2>Agents on this issue</h2><span>${r.lanes.length} lane${r.lanes.length===1?'':'s'}</span></div>${r.lanes.map(l=>`<div class="issue"><span class="issue-number">${esc(l.agent)}</span><div><strong>${esc(l.state)}</strong><p>${esc(l.basis)}</p></div></div>`).join('')}`;}
function issueCard(r,index){
  const h=health(r),events=repoEvents(r),prs=r.prs;
  return `<article class="card ${h.waiting.length?'has-waiting':''} ${h.unknown?'is-unknown':''}" data-repo="${r.id}" data-issue="${r.issue}" style="--repo-color:${r.color}" aria-labelledby="title-${r.id}">
    <div class="card-scroll">
      <div class="card-top"><span>${esc(parentRepo.name)} / Issues</span><span class="position mono">${String(index+1).padStart(2,'0')} / ${String(viewRepos.length).padStart(2,'0')}</span></div>
      <p class="issue-key mono">${h.unknown?'UNCONFIRMED ASSOCIATION · ':''}GH-${r.issue}</p>
      <div class="repo-heading"><h1 id="title-${r.id}"><button class="focus-toggle" type="button" aria-label="Spotlight ${esc(r.name)}" aria-pressed="false">${esc(r.name)}</button></h1></div>
      <p class="intent">${esc(parentRepo.goal)}</p>
      <div class="health ${h.color}"><i class="dot"></i><span class="health-label">${h.label}</span><span class="latest-label">${h.latest===null?'No observation':'Latest '+ageLabel(h.latest)+' ago'}</span></div>
      <div class="counts"><div class="count"><b>${r.lanes.length}</b><span>agent lanes</span></div><div class="count"><b>${h.unknown&&!events.length?'—':events.length}</b><span>hourly updates</span></div><div class="count"><b>${prs===null?'—':prs.length}</b><span>linked PRs</span></div></div>
      <section class="hour"><div class="section-title"><h2>Last hour</h2><span class="event-total">${h.unknown&&!events.length?'Data missing':events.length+' update'+(events.length===1?'':'s')}</span></div><p class="window mono">${timeLabel(minuteNow()-60)} — ${timeLabel(minuteNow())} PDT</p><div class="bars">${bars(r,events)}</div><div class="events">${activityMarkup(r,events)}</div></section>
      <section class="issues">${agentMarkup(r)}</section><div class="waiting">${waitingMarkup(r)}</div>
      <section><div class="section-title"><h2>Next with your agent</h2><span>Continue this lane</span></div>${r.lanes.map(l=>`<p class="next-step">${esc(l.next.replace(/^Review Review /,'Review '))}</p>`).join('')}</section>
      <section><div class="section-title"><h2>Pull requests</h2><span>${prs===null?'Unknown':'Linked to this issue'}</span></div>${prs===null?'<p class="empty-issues">PR inventory unavailable.</p>':prs.length?prs.map(p=>`<div class="issue"><span class="issue-number mono">#${p.number}</span><div><strong>${esc(p.title)}</strong><p>${esc(p.state==='qa'?'Needs QA':p.state==='ready'?'Merge ready':p.state)}</p></div></div>`).join(''):'<p class="empty-issues">No linked PR in the sample inventory.</p>'}</section>
      <section class="checkout-names"><div class="section-title"><h2>Repository workspace</h2><span>${r.clones.length} clones · ${r.worktrees.length} worktrees</span></div><p class="folder-note">Shared repo folders; issue-specific ownership is not inferred.</p>${[...r.clones.map(name=>({name,type:'CLONE'})),...r.worktrees.map(name=>({name,type:'WORKTREE'}))].map(f=>`<div class="folder">${icon('folder')}<span class="folder-name mono">${esc(f.name)}</span><span class="folder-type">${f.type}</span></div>`).join('')}</section>
    </div><footer class="card-footer"><span>${esc(parentRepo.name)} · #${r.issue}</span><span class="sample">LAYOUT C · SAMPLE DATA</span></footer>
  </article>`;
}
carousel.innerHTML=viewRepos.map(card).join('')||'<article class="card" style="--repo-color:#a4abb8"><div class="card-scroll"><h1>Repository unavailable</h1><p class="intent">Choose a repository in Layout B to explore its issues.</p></div></article>';
if(issueMode){
  const backParams=new URLSearchParams();
  if(parentRepo)backParams.set('focus',parentRepo.id);
  if(params.has('position'))backParams.set('position',params.get('position'));
  const close=document.querySelector('.close');
  close.href='layout-b.html?'+backParams;
  close.setAttribute('aria-label','Zoom out to repositories in Layout B');
  carousel.setAttribute('aria-label',parentRepo?parentRepo.name+' issue cards':'Repository unavailable');
  document.title='Flightdeck — Layout C / '+(parentRepo?parentRepo.name:'Issues');
}
let focusedCard=null,suppressClick=false;
function spotlight(card){
  focusedCard=card;
  document.body.classList.toggle('has-focus',Boolean(card));
  carousel.querySelectorAll('.card').forEach(el=>{
    el.classList.toggle('is-focused',el===card);
    const button=el.querySelector('.focus-toggle');
    if(button){button.setAttribute('aria-pressed',String(el===card));if(!issueMode)button.setAttribute('aria-label',(el===card?'Open issues for ':'Spotlight ')+repos.find(r=>r.id===el.dataset.repo).name);}
  });
}
document.addEventListener('click',e=>{
  if(suppressClick&&e.detail!==0)return;
  if(e.target.closest('a'))return;
  const card=e.target.closest('.card');
  if(card&&card===focusedCard&&!issueMode){
    const destination=new URLSearchParams({repo:card.dataset.repo,position:String(carousel.scrollLeft/step())});
    location.href='layout-c.html?'+destination;
    return;
  }
  spotlight(card===focusedCard?null:card);
});
document.addEventListener('keydown',e=>{if(e.key==='Escape'){if(issueMode)location.href=document.querySelector('.close').href;else spotlight(null);}});
carousel.addEventListener('scroll',()=>{if(focusedCard)spotlight(null);},{passive:true});
function step(){return carousel.querySelector('.card').getBoundingClientRect().width+parseFloat(getComputedStyle(carousel).gap);}
function moveTo(index,smooth=true){const reduce=matchMedia('(prefers-reduced-motion: reduce)').matches;carousel.scrollTo({left:Math.min(carousel.scrollWidth-carousel.clientWidth,Math.max(0,index)*step()),behavior:smooth&&!reduce?'smooth':'instant'});}
carousel.addEventListener('keydown',e=>{if(!['ArrowLeft','ArrowRight','Home','End'].includes(e.key))return;e.preventDefault();spotlight(null);const current=Math.round(carousel.scrollLeft/step());moveTo(e.key==='Home'?0:e.key==='End'?viewRepos.length:current+(e.key==='ArrowRight'?1:-1));});
let drag=null,pointerStart=null;
carousel.addEventListener('pointerdown',e=>{suppressClick=false;pointerStart={x:e.clientX,y:e.clientY};if(e.pointerType!=='mouse'||e.button!==0)return;drag={x:e.clientX,left:carousel.scrollLeft,moved:false};(e.target.closest('.card')||carousel).setPointerCapture(e.pointerId);carousel.classList.add('dragging');e.preventDefault();});
carousel.addEventListener('pointermove',e=>{if(pointerStart&&Math.hypot(e.clientX-pointerStart.x,e.clientY-pointerStart.y)>6)suppressClick=true;if(!drag)return;const dx=e.clientX-drag.x;drag.moved ||= Math.abs(dx)>5;if(drag.moved)spotlight(null);carousel.scrollLeft=drag.left-dx;});
function endDrag(){pointerStart=null;if(!drag)return;const index=Math.round(carousel.scrollLeft/step());drag=null;carousel.classList.remove('dragging');moveTo(index);}
carousel.addEventListener('pointerup',endDrag);carousel.addEventListener('pointercancel',endDrag);carousel.addEventListener('lostpointercapture',endDrag);
// Translate two parallel touch contacts; allow native pinch when their separation changes.
let multiTouch=null;
const touchPair=touches=>{const [a,b]=[...touches];return {x:(a.clientX+b.clientX)/2,y:(a.clientY+b.clientY)/2,distance:Math.hypot(a.clientX-b.clientX,a.clientY-b.clientY)};};
carousel.addEventListener('touchstart',e=>{if(e.touches.length===2){suppressClick=true;multiTouch={...touchPair(e.touches),left:carousel.scrollLeft,claimed:false,pinch:false};}},{passive:true});
carousel.addEventListener('touchmove',e=>{if(!multiTouch||e.touches.length!==2)return;const pair=touchPair(e.touches),dx=pair.x-multiTouch.x,dy=pair.y-multiTouch.y;if(Math.abs(pair.distance-multiTouch.distance)>Math.max(8,multiTouch.distance*.06)){multiTouch.pinch=true;if(multiTouch.claimed)carousel.classList.remove('dragging');}if(multiTouch.pinch)return;if(Math.abs(dx)>6&&Math.abs(dx)>Math.abs(dy)&&e.cancelable){e.preventDefault();spotlight(null);multiTouch.claimed=true;carousel.classList.add('dragging');carousel.scrollLeft=multiTouch.left-dx;}},{passive:false});
function endMultiTouch(e){if(multiTouch&&e.touches.length<2){const claimed=multiTouch.claimed&&!multiTouch.pinch;multiTouch=null;carousel.classList.remove('dragging');if(claimed)moveTo(Math.round(carousel.scrollLeft/step()));}}
carousel.addEventListener('touchend',endMultiTouch);carousel.addEventListener('touchcancel',endMultiTouch);
requestAnimationFrame(()=>{
  const focusRepo=!issueMode?repos.find(r=>r.id===params.get('focus')):null;
  const position=Number(params.get('position'));
  const index=issueMode?0:focusRepo?(params.has('position')&&Number.isFinite(position)?position:Math.max(0,repos.indexOf(focusRepo)-1)):(innerWidth>=760?1:0);
  moveTo(index,false);
  requestAnimationFrame(()=>requestAnimationFrame(()=>{
    if(focusRepo)spotlight(carousel.querySelector(`[data-repo="${focusRepo.id}"]`));
  }));
});
let lastMinute=minuteNow();setInterval(()=>{const now=minuteNow();if(now!==lastMinute){lastMinute=now;updateActivity();}},1000);
