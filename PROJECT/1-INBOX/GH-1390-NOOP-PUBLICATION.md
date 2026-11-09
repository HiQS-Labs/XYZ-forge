---
title: Avoid empty post-merge publication gates in primary
status: Proposed
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
| Observed primaryfullgate from no-op push after1389; ownedgatecontained, checkedprimaryclean/published67adb with expectedconfig. No blanketall-stateclaim. | Minimal repair implemented; baseline 3 failures/1 pass, repaired existing suite 227/227 and independent source QA PASS. Next: normal disposable-clone gate, #1384 landing and Skills Army refresh. |

## Recon Map
Existing commit_and_push_phase5_writes commits pendingwrites then unconditionallypushes. No-write/headalreadyremote invokesprepush with emptyrefpairs; hookcorrectlyfailsclosedtofullregistry, inprimary. Callerreturned2afterownedabortalthoughHEADalreadyremote. Thehookremainsunchanged.

## Ordered plan
1. Fetchintegrationbeforepublication andrequire nonemptylocal/remoteIDs -> unreadable/fetchfailurestop.
2. EqualIDsneednopush; unequalIDsretainnormalpush pluspostpushfetch -> finalclean/equalitychecksremainbinding.
3. Existinggh436 coveragewitnessesbaselineRED/fixedGREEN noop, unpublishedwrites, fetcherrors -> no newsuite/runner/flag.
4. Freshindependentreviewandnormalfullgate indisposableclone -> foldrelatedsafetyfixinto1384; preserveprior558sgateaspreviouscompositiononly, thenrefreshdeployedskillfrompublishedprimary.

## Bet and rollback
Costly sharedpublicationsurface. Skiponlyunneededremoteoperationwhenfreshrefproofshowsalreadydurable; neverbypasspublicationfornewdata. Revertthesmallfunctionchangeifneeded; preserveincidentlogsandallactualclones.1390fixdoesnotcoalesce nonemptyperlandingpushes;1383remainsopen.

## Published capture disposition

The implementation remains an unqualified local candidate at4e015c24a. Full registry refused the first publication405/408; the later retry was stopped to reserve the original closeout cutoff. This evidence-only capture does not merge or install the implementation, close1390, or claim full qualification. Source/test patch is retained as data under TESTS-RESULTS; it is not an executable product change. The local task branch and all helper clones remain preserved.
