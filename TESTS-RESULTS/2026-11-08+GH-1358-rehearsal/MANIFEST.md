# Phase A short attempt manifest

Candidate runtime cd404cfd1fd9a423bffa1a04821330e9d2552850; accounting checkpoint 70847aa14. Initiating agent present; this is preparation/manual-control inspection, not a scheduled qualification window. Maximum 45 minutes from 2026-11-08T06:55:38.182075+00:00. Stop sooner if deployed composition cannot be identified. Zero builder dispatches and zero new spending permitted; builder/reviewer production turn caps and usage ceiling UNKNOWN, hence production dispatch blocked. One independently authorized evidence QA review; no runtime implementation. Operator attention budget zero requested interventions. Historical repair counters retained, maximum three per blocker, no additional repair authorized outside this seam.

Known commands: releases_app.py roadmap pickup --issue-num N [--dry-run]; jog add/list/resume/run/retry-gate/land/reconcile. These are manual primitives, not evidence of deployed composition. Read-only help, local scheduler inventory, connected T3 schedule inventory and owning source/docs inspection are permitted controls with 60-second command deadlines. Preconditions for dependent execution: identified deployment/config, independent observer, exact caps, genuine planner-selected workload with three PR-ready items, and prior #1295 requirement for factory-authored packets. These are not yet met. Do not execute dependent transitions until met.

| Transition | Expected result | Failure owner |
|---|---|---|
| Discovery/pickup/add/checkpoint | One genuine no-row admission, duplicate wake no duplicate effect | #1175/#1200/#1207 |
| Delivered/stale refusal | Ineligible rejected, eligible admitted | #1175/#1200 |
| Dependency hold/advance | Hold preserved and independent work advanced | #1175/#1200 |
| Lane interruption/cold start | Park/reproject without duplicate refire | #1200 |
| Supervisor loss | Scheduled resume without chat command | #1168/#1175/#1188 |
| Changed candidate approval | Premerge stale head refused | #1200 |
| Approved landing chain | Reconcile/land then automatic next selection | #1208/#1207/#1175 |

Each transition deadline bounded by remaining 45-minute attempt; exact execution deadlines unavailable means NOT READY, never implicit unlimited execution. Missing positive or negative witness means NOT EXERCISED. Natural #1356 failure receipts reused for diagnostic context only, not rebranded as this composition's passing controls. Stop preserves all evidence; no cleanup, merges, automation installation or overnight start.
