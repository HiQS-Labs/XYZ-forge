---
gh_issue: 557
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/557
title: "An unverifiable acceptance section reads as ready — 'unknown' must block on a frozen manifest entry"
status: 2-WORKING
created: 2026-08-15
updated: 2026-08-15
owner: unassigned
doc_type: capture
complexity: 3
risk: 3
effort: 2
ratings_provisional: true
related:
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/400 — the fidelity check this arrives through; `unknown` is its pass-through case"
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419 — a check never observed failing is not evidence"
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/551 — a resolver that cannot determine its answer returns a plausible default instead of refusing; this is that shape inside preflight"
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/555 — the same defect class one level up, fixed in meter-release.sh Half B the same day"
goal: >
  Stop a frozen release manifest from being satisfiable by acceptance criteria whose provenance was
  never established, without turning an outage or an ordinary exploratory lane into a hard stop.
---

## Status

| What was just completed | What's next |
|---|---|
| Filed and fixed 2026-08-15. `cause` added to the fidelity verdict; a structural `unknown` blocks on a frozen manifest member; gate registered; negative control recorded (5 pass / 11 fail pre-fix). | Review and merge. Meter entries #378, #382, #491 and #551 still need `## Acceptance` sections authored onto their GitHub issues — that is authoring work, out of scope here, and this gate now refuses those lanes until it is done. |

**Not a Meter member.** Meter's manifest is frozen at seven by explicit operator decision and stays
frozen; this issue is deliberately unmilestoned. It was found while re-running preflight across that
manifest, which is provenance, not membership — discovery is not admission.

## The defect

`check_acceptance_fidelity()` returns `match`, `diverged`, or `unknown`, and only `diverged` blocked
(`utils/py/swarm_preflight.py:1338`). `unknown` fell through to `ready (exit 0)`.

Observed live against Meter manifest member #382, with `gh` authenticated and the network healthy:

```
  inlined-acc : 6 criterion(a) from the acceptance-section
  acceptance  : unknown — issue #382 has no '## Acceptance' section — nothing to copy from
  verdict     : ready (exit 0)
```

Six criteria in the capture doc, none on the issue, lane declared ready. Neither the builder nor the
reviewer ever sees the issue, so nothing downstream could have caught it — which is precisely the
GH-400 failure, arriving through GH-400's own pass-through case.

## Why one status was hiding two different situations

`unknown` was returned for causes that need different handling and printed identically:

| cause | nature | correct handling |
|---|---|---|
| `fetch-failed` | `gh` missing, unauthenticated, or offline | advisory everywhere — an outage is not a contract violation |
| `no-issue-section` | the issue itself states no criteria | structural; no retry will ever verify them |
| `no-gh-issue` / `doc-unreadable` | nothing to compare | advisory |

This cost a real diagnosis. During the 2026-08-14 DNS outage every Meter packet read `unknown` and it
was attributed to DNS. When DNS was restored the same entries still read `unknown` — for the second
reason entirely — and no output distinguished them.

## Why the block is narrow

Blocking every acceptance-less issue would be a hard stop on ordinary exploratory and
externally-reported work, and blocking on an outage would have halted this whole repo on 2026-08-14.
Only a **frozen manifest member** blocks, and only on the **structural** cause. A manifest member has
already been declared load-bearing and has a release goalpost built around it; criteria that came
from nowhere can turn that goalpost green against work nobody specified.

## How manifest membership is determined

From each `test/*-release.sh` goalpost's `MANIFEST=(...)` array — the documented row format
`"<issue>|<gate test file, or '-'>|<note>"` — which the goalpost itself already cross-checks against
`RELEASES.md` (*"a boundary that disagrees with itself is not frozen"*).

`RELEASES.md`'s `Manifest:` prose is deliberately **not** parsed. It names many issue numbers that
are explicitly not members: #509 (retired from Meter), #358 Phase 2 (moved to Lantern), and the nine
root-cause siblings cited under #551. A regex over that prose would read every one as a member and
block unrelated lanes. A false positive is far worse than a false negative here — it stops work that
was never in scope.

## Acceptance

- [ ] `swarm-preflight` distinguishes the transient cause (issue could not be fetched) from the
      structural cause (the issue has no `## Acceptance` section) — they no longer share a single
      `unknown` status, and the packet states which one occurred.
- [ ] When the target issue is a member of a frozen release manifest in `RELEASES.md`, a
      structural `unknown` BLOCKS: preflight exits non-zero and names the issue number and the
      remedy (author the `## Acceptance` section onto the GitHub issue), rather than emitting
      `ready`.
- [ ] For an issue that is NOT a frozen manifest member, the existing non-blocking behaviour is
      unchanged — an ordinary lane with no acceptance section still reaches `ready`, and this is
      asserted rather than assumed.
- [ ] A transient `unknown` (offline, `gh` missing, unauthenticated) remains non-blocking on
      every path, and says plainly that acceptance fidelity was NOT verified. Being unable to
      reach GitHub must not become a hard stop on all local work.
- [ ] The packet's provenance line for a structural `unknown` states that the issue has no
      criteria to copy from, so a reader of the packet alone can tell an unverified lane from a
      verified one (`utils/py/swarm_preflight.py:1540-1542`).
- [ ] A registered gate covers the above and is added to `validate.sh`'s `TESTS`.
- [ ] A negative control is recorded under `test/baselines/` per GH-419, observed RED before the
      fix: the pre-fix code must be shown emitting `ready (exit 0)` for a manifest member whose
      issue has no `## Acceptance` section. A check never observed failing is not evidence.

## Acceptance — deviations from the issue

- [changed] `When the target issue is a member of a frozen release manifest in RELEASES.md, a
  structural unknown BLOCKS: preflight exits non-zero and names the issue number and the remedy
  (author the ## Acceptance section onto the GitHub issue), rather than emitting ready.` ->
  `Membership is read from each test/*-release.sh goalpost's MANIFEST=(...) array — which the
  goalpost already cross-checks against RELEASES.md — rather than by parsing RELEASES.md's
  Manifest: prose directly. The blocking behaviour, exit code and message are exactly as written.`
  — reason: the `Manifest:` line is prose and names non-members by design (#509 retired, #358
  Phase 2 moved, #551's nine root-cause siblings). Parsing it would have blocked unrelated lanes,
  which is a worse failure than the one being fixed. The goalpost arrays are the same boundary in
  machine-readable form, and the goalpost fails if the two ever disagree.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "utils/py/swarm_preflight.py", "pattern": "no-issue-section" } ],
  "artifacts":   [
    "utils/py/swarm_preflight.py",
    "test/gh557-unknown-blocks-manifest.sh",
    "test/baselines/GH-557-negative-control.md",
    "validate.sh"
  ],
  "remediation": { "source": "issue#557", "criteria": "a structural `unknown` acceptance verdict blocks on a frozen manifest member and stays advisory everywhere else" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```

## Evidence

- Gate: `test/gh557-unknown-blocks-manifest.sh` — **16/0**, hermetic (`gh` stubbed, local bare
  origins, no network).
- Control: `test/baselines/GH-557-negative-control.md` — pre-fix **5 pass / 11 fail**, pin observed
  as `expected exit 5, got 0`.
- The three assertions that PASS pre-fix are load-bearing: a detector that refused every
  acceptance-less issue would satisfy the pin and fail all three. A 16/16 red would have been the
  weaker result.
- Full `./validate.sh` run recorded three failures, of which exactly one was this change's
  (`roadmap-dashboard.sh`, a generated artifact — regenerated). The other two pre-exist on
  `development` and are proven so rather than asserted: `releases-skill.sh` is registered in
  `validate.sh` on `origin/development` while `test/releases-skill.sh` does not exist there
  (rc=127), and `gh460-pipe-buffer-sigpipe.sh` fails on `test/gh544-pre-push-gate.sh`, which is
  byte-identical to `origin/development` in this branch.
