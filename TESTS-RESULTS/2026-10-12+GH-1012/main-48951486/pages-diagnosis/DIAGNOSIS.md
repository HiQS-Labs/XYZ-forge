# Pages diagnosis — exact resulting main

Run 38326961150 (attempt1), push on main 4895148683120b8b6f808d4dcd66267a3754fd2c, completed failure 2026-10-13T00:23:18Z (October12 17:23:18PDT).

Build job115067757652 succeeded. Site regeneration and Pages artifact upload succeeded; artifact11781540120, digest sha256:dae8f68ee478d51198dd12de5483e7a94daa5a072da748e7de4d5f9041c0bc5d, 50,661bytes, expires 2026-10-14T00:23:11Z. Deploy job115067817030 failed before any steps, with runner_id0. The archived logs contain build logs only. Deploy check annotations explicitly state: Branch "main" is not allowed to deploy to github-pages due to environment protection rules.

Current environment policy: github-pages has custom_branch_policies=true, protected_branches=false. The branch-policy endpoint returns total_count1: policy58962659, type branch, name development. No main or tag policy is returned. Environment can_admins_bypass=true is observed metadata, not authorization or a recommended bypass.

The workflow at exact main M explicitly triggers push branches [development, main], uploads PAGES, and deploys to environment github-pages. Thus the workflow's declared main publishing intent disagrees with the environment's permitted branch set. Pages API reports build_type workflow, public=true, source branch development; this is supplementary metadata and does not override the explicit Actions/environment restriction.

Existing public site GET at 2026-10-13T01:19:12Z returned HTTP200, text/html, 13,129bytes; Last-Modified Mon12Oct2026 21:55:30GMT. This verifies availability of the existing homepage at observation time, not exact source revision, all linked pages, or publication of M. The failed run blocks the new main artifact publication; it does not establish an outage.

Operator decision is required before any correction: allow main in github-pages (retain development if intended) to match the workflow, or affirm development-only publication and authorize an appropriate workflow change. Current continuation authorizes diagnosis only; no protection/permission change, bypass, rerun, deployment, code change, test, or external posting was performed.

Sources:
- Run: https://github.com/HiQS-Labs/XYZ-forge/actions/runs/38326961150
- Failed deploy: https://github.com/HiQS-Labs/XYZ-forge/actions/runs/38326961150/job/115067817030
- Exact workflow: https://github.com/HiQS-Labs/XYZ-forge/blob/4895148683120b8b6f808d4dcd66267a3754fd2c/.github/workflows/pages.yml
- Environment API: https://api.github.com/repos/HiQS-Labs/XYZ-forge/environments/github-pages
- Policy API: https://api.github.com/repos/HiQS-Labs/XYZ-forge/environments/github-pages/deployment-branch-policies
- Existing site: https://hiqs-labs.github.io/XYZ-forge/

Raw evidence: run.json, jobs.json, deploy-annotations.json, environment.json, branch-policies.json, workflow.json and decoded pages.yml, artifacts.json, run-logs.zip plus decoded build logs, pages.json, existing-site-response.json and homepage body. stderr sidecars preserve endpoint failures if present.
