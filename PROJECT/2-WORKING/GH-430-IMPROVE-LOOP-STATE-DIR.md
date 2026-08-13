---
gh_issue: 430
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/430
title: "improve-loop.sh defaults --state-dir to /tmp — provenance.jsonl evaporates, so no run evidence survives"
status: 2-WORKING
created: 2026-08-13
updated: 2026-08-13
owner: unassigned
doc_type: capture
complexity: 1
risk: 2
effort: 1
ratings_provisional: true
goal: >
  Stop improve-loop.sh writing its only audit trail to a process-scoped temp path, so a run
  cited as proof leaves an artifact that can be re-examined, and record the process rule that an
  uncommitted provenance claim is treated as no claim.
---

## Why

`relay-automation/improve-loop.sh:70` defaults the state directory to a process-scoped temp path:

```sh
STATE_DIR="${STATE_DIR:-${TMPDIR:-/tmp}/improve-loop.$$}"
```

Independently reproduced at line 70 during the 2026-08-13 `/10days` sweep — unchanged.

The loop's audit trail is written to `$STATE_DIR/provenance.jsonl`. A full-tree search finds
**zero** `provenance*.jsonl` anywhere in the repo. In particular the 2026-06-30 live-agent run
cited in `ROADMAP.md` and in the GH-50 close as "proven … provenance logged" has no surviving
artifact: the log evaporated with the temp directory.

`provenance.jsonl` is the loop's only audit trail — every accept/reject, the metric trace, the
spend. With the default under `/tmp`, every run past and future produces claims that cannot be
re-examined: the exact "closed as success, unverifiable later" pattern the GH-40 post-close review
documented across this feature.

## Key concepts

- **Placement constraint (from GH-396):** `.tick/` is gitignored and `rtl_enforce` deliberately
  does not inspect ignored files, so a gitignored state dir inherits *zero* containment
  protection. A **tracked** path is the safer home for anything that will be cited as evidence.
- The issue offers two alternatives for item 1 — refuse to start without `--state-dir`, or default
  to an in-repo path. **This lane takes the in-repo-default branch**, because refusing to start
  breaks every existing caller while the default change is backward-compatible. Recorded here
  rather than left implicit; the operator can invert it.

## Acceptance

Authored by `/10days` — the tracking issue has no `## Acceptance` section, so there is no block
to copy verbatim. These criteria transcribe the issue's numbered `**Fix:**` items 1–2, with the
item-1 branch chosen as recorded above.

1. `relay-automation/improve-loop.sh` no longer defaults `STATE_DIR` to a `${TMPDIR:-/tmp}` path.
2. The new default is a path **inside the repository** that is **tracked** (not under the
   gitignored `.tick/`), per the GH-396 placement constraint.
3. An explicit `--state-dir` argument still overrides the default, unchanged.
4. A test asserts the new default: running the loop without `--state-dir` writes
   `provenance.jsonl` to the in-repo tracked path, and that path is not under `/tmp` or `$TMPDIR`.
5. The test is registered in `validate.sh` so it actually runs.
6. Documentation records the process rule: any run cited as proof in an issue, PR, ROADMAP entry,
   or decision record must have its `provenance.jsonl` committed in the same PR — an uncommitted
   provenance claim is treated as no claim.
7. `bash validate.sh` exits 0.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "type": "grep_present", "path": "relay-automation/improve-loop.sh", "pattern": "STATE_DIR:-\\$\\{TMPDIR:-/tmp\\}" }
  ],
  "artifacts":   [
    "relay-automation/improve-loop.sh",
    "test/",
    "validate.sh",
    "AGENTS.md"
  ],
  "remediation": { "source": "issue#430", "criteria": "Default improve-loop state dir to a tracked in-repo path and pin it with a registered test" },
  "lanes":       { "agy_safe": [ "relay-automation/improve-loop.sh", "test/" ], "orchestrator_only": [ "validate.sh", "AGENTS.md" ] }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified.
The `fix_probe` detects the BUG (the `/tmp` default still present), per swarm-preflight polarity.
