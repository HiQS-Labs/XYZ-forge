---
title: Avoid empty post-merge publication gates in primary
status: Complete
created: 2026-11-09
updated: 2026-11-09
owner: noel
gh_issue: 1390
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1390
doc_type: bug
complexity: 2
risk: 2
effort: 1
phases: 1
ratings_provisional: true
goal: Avoid empty publication pushes in primary while retaining normal gates for unpublished commits.
---

# GH-1390 — empty publication safety

## Status

| What was just completed | What's next |
|---|---|
| Reviewed/tested fix merged in PR1393 and deployed through Skills Army HQ; actual primary no-op fetched and verified without push | Issue1390 complete; Pulse remote distribution warning remains separate; no next trial started |

## Recon Map
Existing commit_and_push_phase5_writes commits pendingwrites then unconditionallypushes. No-write/headalreadyremote invokesprepush with emptyrefpairs; hookcorrectlyfailsclosedtofullregistry, inprimary. Callerreturned2afterownedabortalthoughHEADalreadyremote. Thehookremainsunchanged.

## Ordered plan
1. Fetchintegrationbeforepublication andrequire nonemptylocal/remoteIDs -> unreadable/fetchfailurestop.
2. EqualIDsneednopush; unequalIDsretainnormalpush pluspostpushfetch -> finalclean/equalitychecksremainbinding.
3. Existinggh436 coveragewitnessesbaselineRED/fixedGREEN noop, unpublishedwrites, fetcherrors -> no newsuite/runner/flag.
4. Parent independently reviews this B01-based composition and runs the existing full registry in a disposable full clone -> require current committed-state evidence before parent-owned PR/landing/deployment. No tests or gates run in this linked checkout.

## Bet and rollback
Costly sharedpublicationsurface. Skiponlyunneededremoteoperationwhenfreshrefproofshowsalreadydurable; neverbypasspublicationfornewdata. Revertthesmallfunctionchangeifneeded; preserveincidentlogsandallactualclones.1390fixdoesnotcoalesce nonemptyperlandingpushes;1383remainsopen.


## Current bounded task scope

This is a new issue-specific GH-1390 task from development B01 `b01b621e1f915ba259239e9cb480f1405fe666c9`, reusing the reviewed production and existing gh436 controls from retained source `4e015c24a` against E26 `e26e63407491f9a02e93bb67462efeb27f257513`. The required `goal` is corrected above. Reuse issue 1390; no duplicate issue or old GH-1384 ledger/config is imported.

Original GH-1384's two repair slots are exhausted, not reset. Preserve the first normal push failure (405/408: GH123 pooled/serial failures and missing-goal PDDA/sentinel failures), the later aborted retry, and the targeted GH123 6/0 result without converting them to a full pass. The retained source QA and gh436 227/227 results apply to the old composition, not this candidate. The aborted retry is retained here as reported task history; no additional retry receipt was present in the retained GH-1390 evidence directory.

Window: 2026-11-09 03:48:20–05:18:20Z. Parent maximum: two qualification attempts, each <=1800 seconds; at most three routine repair rounds per new blocker. Token budget unknown. This implementation sub-agent only composes and commits; parent owns gates, independent reviews, PR, merge and deployment. No new builder, test suite, gate machinery, hook weakening, branch deletion or counter reset. Original policy SHA-256 remains `375ac61e7589b6a7ae6da78da2a696dd1c95f193a512bd5b25ac3af58b2cf259`.

Task rubrics: safety/security require fresh successful fetch, nonempty readable IDs, ordinary push plus post-fetch for unequal IDs, and final cleanliness/equality; maintainability reuses the existing helper and gh436 controls; performance avoids only the empty push, with no current speedup claim. Proposed PRS axes are 95/90/50/85; preserve any existing rating/override through supported pickup. Rollback is reverting the narrow function change; preserve evidence and checkout state.

## Current sanity-check and qualification evidence

SANITY-CHECK: Fix now. The empty publication path exposes primary to a full registry without new durable data; the common existing publisher is the origin/fix site, not the hook's correct fail-closed fallback. Fresh normal qualification remains necessary before delivery. Required goal metadata is corrected. GH123 moving queue75after22s was a real prior serial failure of unknown cause; current and retained GH123 source blobd4597587 is identical, and the later restoration full408/408 passed. This supports a fresh composed qualification on the sole host slot, not a harmless-flake claim. No required gate disabled or narrowed; fail again => diagnose actual failure before retry.

Fresh independent composed source QA Approved ataf84ecbc2. Current existing four controls: baseline3fail/1pass, candidate4pass. Manual local bare-Git fixture witnessed equal-head skip (zero hook calls), dirty writes committed and genuinely published through ordinary pre-push (one hook call), and subsequent equal-head skip (no extra call), clean and actual remote equality. No live primary push in the probe. Parent recovered historical aborted retry result/owned-stop metadata from retained temp; both are now preserved alongside the prior failure.

Two probe setup corrections are disclosed: initial baseline function globals did not share test mock bindings (invalid negative result); initial manual fixture lacked its exact temp parent. Corrected probes are separate records, no production repair. Cost includes these plus prior failures; tokensunknown. Fresh normal full qualification is next; no current fullpass claim.

## Fresh full qualification

First new issue-specific normal full push passed408/408, including GH123parallelrc0, on d336b6d7db14a5bc3eb4506af23cc72bd0013dc4; hook524s, outer526.789s. Independent fullclone identity before/after unchanged. Prior405/408 and abortedretry remain failures; no gatewaiver or second attempt. Evidence-only normal publication, exact-head hosted checks, approved landing and HQdelivery parity remain pending.

## Delivered outcome

PR1393 finalafbab719 exact-hosted42559882821SUCCESS and parent outerPASS; merge4df6b0a4acd4702add981f241aecaab76ec7985c, canonical cleanpublicationfb8b766718c54c8e64037418105a24ae10b680bf. One new fullqualification408/408(hook524s) and docs64s/70s; original405/408/abortedretry remain historical failures and counters unchanged. Required premerge gate refused on RESTcore0/5000; parent-owned04:44 continuation retried after04:43:45 reset and gatepassed, no API/account/gate bypass.

HQ manager alone updated local payload from clean merged4df6b0a4, digest3ac107523f1157a2a8e588895b3706a44cb37149f46fe0f75f72c326ae92210d, matchingreceipt/wholefolder/6links. Pulsecommit82d38e8b9, remote distribution unverified with STALE_PULSE_COLLECTION behind1; no history force/rebase/reset. App picker refresh unverified. Delivered primary no-op probe: realfetch and finaldurabilitychecks, zero pushrequests,0.421s; spy would reject unexpectedpush before execution. Earlier actual localbareGit dirty-write probe proves unpublishedwrites stillcommit/publish through normalhook. No speedup/coalescingclaim.

Agent-assisted Flywheel1B, start03:48:20Z, deadline05:18:20Z; tokensunknown. Priorfailurecosts, two manualprobe setupcorrections and quotawait are retained; no new productionrepair, newbuilder or second fullattempt. No othermerge/configexperiment/cleanup/trial/promotion. ExactfinalSHA/end recorded in1390/1386 after normalbookkeepingpublication. Originalpolicyhash375ac61e7589b6a7ae6da78da2a696dd1c95f193a512bd5b25ac3af58b2cf259 unchanged.
