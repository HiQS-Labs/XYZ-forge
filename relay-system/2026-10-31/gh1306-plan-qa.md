---
Goal: Plan QA — GH-1306 intake.py update records a missing source receipt for an identical payload
Date: 2026-10-31
NEXT: codex
STATUS: In Review
---

# Context

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1306 (upstream reference HiQS-Labs/XYZ-skills-army-mini#9). Canonical plan: `PROJECT/2-WORKING/GH-1306-HQ-UNCHANGED-SOURCE-RECEIPT.md` (embedded below). Source to check claims against: `skills/3-weekly/skills-army-hq/scripts/intake.py` — `source_record` (L200), `inventory` (L289), `copy_line` (L384), `commit_skill` (L459), `transact`/`finish` (L590–617), the `add`/`update` branch in `main` (≈L787–808) and the post-apply commit block (≈L844–858). Covering suite: `test/skills-army-hq.sh` → `test/test_deploy_skills.py`.

Operational envelope: a one-branch change in a local single-operator CLI. No new tests or registry entries (GH-831), no new machinery. Grade against the issue goal and non-goals, not hypothetical multi-tenant threat models. Reviewer turns cannot run git, so the relevant code is embedded.

Questions:
1. Is the root cause right (the equal-digest early return precedes any receipt comparison)?
2. Is the "Unchanged" condition right (held receipt names this source AND its digest equals the deployed digest), or is it too wide/narrow?
3. Is skipping `commit_skill()` for a receipt-only update correct given state/catalog/history are untracked machine state?
4. Does a receipt-only `transact` with empty `actions` pass `validate_receipt`/`finish` unchanged? Any recovery-path risk?
5. Are the smoke cases (red control, main, rerun, changed-payload) and the existing suite sufficient as falsifiable checks?

# Plan (embedded)

---
title: skills-army-hq intake.py update cannot adopt a skill whose payload already matches its source
status: Working
created: 2026-10-31
updated: 2026-10-31
owner: noelsaw1
gh_issue: 1306
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1306
doc_type: bugfix
complexity: 1
risk: 2
effort: 1
phases: 1
non_goals:
  - Moving Skills Army HQ authorship to XYZ-skills-army-mini (#882, mini#2)
  - A RECEIPT-STALE status report or post-pull reconciliation command (#1157 item 4)
  - Any change to payload copy, backup, link or drift semantics
related:
  - GH-1157 (stale receipts; item 2 asks for a no-recopy receipt refresh)
  - HiQS-Labs/XYZ-skills-army-mini#9 (same defect, upstream reference)
goal: >
  `intake.py update NAME --source PATH` records the source receipt for a deployed skill whose bytes
  already equal the source, without recopying, so an unadopted identical skill can be adopted
  through the supported CLI.
---

# GH-1306 — intake.py update cannot adopt an identical skill

## Status

| What was just completed | What's next |
|---|---|
| Captured, parked, rated, promoted; recon and plan written | Codex plan QA |

## Symptom

`intake.py update NAME --source PATH` prints `Unchanged: NAME` and exits whenever the source digest
equals the deployed digest, without checking the receipt. A `manual/unadopted` skill that is already
byte-identical to its owning repo can never be adopted; hand-editing `.deploy-skills.json` is forbidden.
Seen 2026-10-30 on the MBP 14" collection: 10days, dry, file-xyz-bug, review-code-xyz, review-pr-xyz,
sanity-check, triangulate and xyz.

## Rating

`rated 40/35/50/85` (2026-10-31). Severity 35: provenance and drift visibility are lost for the
affected skills; no data loss, no blocked work, and payloads stay correct. Priority 40: eight skills on
one device are invisible to drift checks today, and a fresh device hits the same wall. Appeal 50
(neutral, no operator preference stated). Effort 85: one branch in one function, existing transaction
path. Recurrence (2026-10-17..10-31 vs prior 14 days): one incident in the window; the related
stale-receipt class appears once in #1157 (2026-10-18). No incidents before that; trend unknown.

## Recon (base 5a93dcfb, origin/development)

- Entry: `skills/3-weekly/skills-army-hq/scripts/intake.py` `main()`, `add`/`update` branch. `source_record()` builds the
  receipt (source, repository, commit, dirty, digest, updated, prerequisites). `found` comes from `inventory()`
  (deployed digests). The early return `if before == record["digest"]: print("Unchanged: …"); return 0` runs before
  any receipt comparison, so state is never written.
- State writer: `transact()` -> `finish()` writes `.deploy-skills.json`, `targets.json`, `catalog.md`, README and
  history. An empty `actions` list is already valid (`catalog`, `adopt-existing` use it).
- Post-apply: `commit_skill()` commits the skill folder in the Pulse repo. State, catalog and history are untracked
  machine state, so a receipt-only update has nothing to commit and would print the misleading
  "WARN not committed … the hourly pulse stays blocked".
- Receipts without `source` come from `catalog` (`state["skills"].setdefault(name, {**info, …})`); `copy_line()` shows
  them as `manual/unadopted`.
- `add` never reaches the equal-digest branch with a deployed skill (`name not in found` is required), so only
  `update` changes behaviour.
- Covering suite: `test/skills-army-hq.sh` (wraps `test/test_deploy_skills.py`, registered in `validate.sh:549`).

## Fix (one function, one file)

In the `add`/`update` branch, when `before == record["digest"]`:
- If the held receipt already names this `source` and its `digest` equals the deployed digest, keep
  `Unchanged: NAME` and exit 0 (today's behaviour for adopted skills).
- Otherwise continue as a **receipt-only** update: no `archive()`, no `stage_payload()`, empty `actions`;
  `details` carries `"receipt_only": true`; the preview prints `skills-army-hq: will RECORD source <src> @ <commit>
  for NAME (payload already identical; nothing copied)`. Prerequisites are preserved by the existing line.
- After apply, skip `commit_skill()` for a receipt-only update (nothing tracked changed) instead of printing the
  blocked-pulse WARN.

Non-goals as in frontmatter. No new suites (GH-831). Rollback: revert the one hunk.

## Verification

1. Existing suite `bash test/skills-army-hq.sh` green (no regression in update/add/self-update paths).
2. Smoke (GH-1088), in a disposable copy of a collection under `TESTS-RESULTS/2026-10-31+GH-1306/`:
   - red control on the pre-fix file: unadopted identical skill -> `Unchanged`, receipt has no source;
   - main path: same command with `--apply` -> receipt records source/commit, payload digest and files unchanged,
     no backup ZIP, no commit attempt WARN;
   - adjacent path: rerun the same command -> `Unchanged` (idempotent);
   - adjacent path: a changed payload still copies (normal update unaffected).
3. Full gate via pre-push (skills-army-hq scripts route to the full tier), once on the final commit.

## After merge

Refresh the deployed manager (`intake.py --apply update skills-army-hq`), then adopt the eight skills with
`intake.py --apply update NAME --source <forge path>`; done when `sync.py --status` shows 0 drift and each copy line
names its source.

# Code excerpt: add/update branch and post-apply block (intake.py, base 5a93dcfb)

```python
                details = {"manager": "skills-army-hq", "actions": actions}
            elif args.command in ("add", "update"):
                raw = args.source if args.command == "add" else args.source or state["skills"].get(args.name, {}).get("source")
                require(raw, "No source receipt; provide --source")
                source, record, ignored = source_record(raw)
                name = record["name"]
                if args.command == "update":
                    require(name == safe_name(args.name) and name in found, "Update name/source mismatch or absent skill")
                require(not within(source, root) and not within(root, source) and source != root, "Source/collection overlap")
                require(name not in found or args.command == "update", f"Skill already exists: {name}; use update")
                before = found.get(name, {}).get("digest")
                if before == record["digest"]:
                    print(f"Unchanged: {name}"); return 0
                details = {"name": name, "source": str(source), "before": before, "after": record["digest"], "commit": record["commit"]}
                if apply:
                    if before:
                        details["backup"] = archive(root, root / name)
                    actions.append(stage_payload(root, source, before, record["digest"], name, ignored))
                else:
                    print(f"skills-army-hq: will COPY {source} @ {record['commit'][:12]} into {root / name}; "
                          "apps link to that copy, not to the source", file=sys.stderr)
                record["prerequisites"] = state["skills"].get(name, {}).get("prerequisites", [])
                state["skills"][name] = record
            elif args.command == "remove":
                name = safe_name(args.name)
    # …
                details = {"skills": sorted(found)}
            print(json.dumps({"operation": args.command, "apply": apply, **details}, indent=2))
            if apply:
                transact(root, state, config, actions, args.command, details)
                if args.command in ("add", "update", "remove"):
                    origin = f" from {Path(details['source']).name}@{details['commit'][:12]}" if details.get("commit") else ""
                    if owned_paths and regular_bytes(root / "README.md") != regular_bytes(root / "skills-army-hq" / "README.md"):
                        owned_paths = ()
                    result = commit_skill(root, details["name"], f"vendor: {args.command} {details['name']}{origin}", owned_paths)
                    if result and result["committed"]:
                        print(f"skills-army-hq: committed {details['name']} in {result['repo']} ({result['commit']}); "
                              "git-pulse pushes it on its next run", file=sys.stderr)
                    elif result:
                        print(f"skills-army-hq: WARN not committed in {result['repo']}: {result['reason']} — "
                              "commit by hand or the hourly pulse stays blocked", file=sys.stderr)
        return 0
```

# Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
