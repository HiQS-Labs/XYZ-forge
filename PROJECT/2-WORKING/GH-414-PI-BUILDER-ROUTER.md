---
gh_issue: 414
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/414
title: "GH-414 — the marathon router's Pi rejection is now largely stale: two of five claims already fixed by GH-451"
status: "2-WORKING — captured 2026-08-10 for release 0.3.0 Nightwatch. Verified against `development` @ 40a75da. Every claim in the issue re-checked against the tree; two of five no longer hold. Awaiting preflight."
created: 2026-08-10
updated: 2026-08-10
owner: noel
doc_type: project
release: "0.3.0 Nightwatch"
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
roadmap_exempt: false
related:
  - "#451 — PR #452 (commit 66d2945f, merged 2026-08-09) already routed `pi*` through `utils/py/marathon_drive.py`'s `route_agent` and gave `relay-automation/marathon-agent.sh` its `PI_AGENT` branch. #451 was filed 2026-08-08 and is still OPEN on GitHub; ROADMAP.md's line for it still reads 'captured 2026-08-08' and points at its 1-INBOX doc, unreconciled against the code that already shipped."
  - "#308 — the frozen-twin freeze governing `relay-automation/marathon-drive.sh`; any edit to it, including a comment, needs a `Frozen-twin-exception:` trailer."
  - "#295 — shipped the Pi shims (`relay-automation/pi-turn.sh`, `utils/py/pi-turn.py`) this issue's routing depends on."
non_goals:
  - "Changing Pi's default status. Codex and agy remain the defaults; this only keeps Pi selectable where GH-451 already made it selectable."
  - "Unfreezing or editing `relay-automation/marathon-drive.sh`. GH-451's own non-goals already ruled this out, and nothing in this lane's remaining scope needs it."
  - "Re-doing what GH-451 already shipped. `route_agent` accepting `pi*` and `marathon-agent.sh` dispatching `PI_AGENT` are DONE on `development`; re-implementing either would be redundant with a merged PR."
  - "Any judgement on Pi's build quality. GH-303 already measured that separately (91 trials, 0 failures)."
goal: >
  Issue #414 was filed 2026-08-03 against a marathon router that rejected `pi` as a builder id
  outright. On 2026-08-09, PR #452 (GH-451) shipped Python-side Pi routing — unrelated in filing but
  overlapping in code. Re-verifying #414's own evidence table against the current tree shows two of
  its five claims no longer hold. The remaining, narrower gap is: no regression case in
  `test/marathon-drive.sh` pins the Pi lane, and the frozen Bash twin's now-real divergence from the
  Python driver is undocumented. Acceptance criteria are unchanged (carried verbatim from the issue,
  per repo policy) — this doc records which of them are already satisfied by code on disk.
---

# GH-414 · the Pi-router defect is half-fixed already, undocumented as such

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10 as a lane of release 0.3.0 Nightwatch. Every claim in the issue's own "Evidence" table was re-verified against `development` @ `40a75da` rather than trusted — two of five no longer hold, because GH-451/PR #452 (merged 2026-08-09, six days after #414 was filed) shipped the Python-side routing independently. | Preflight, then fire as a single small phase: pin a Pi-builder regression case in `test/marathon-drive.sh` and record the Bash/Python divergence explicitly. Pending operator go. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/414

## The defect

Issue #414, filed 2026-08-03, describes a marathon router that rejects `pi` as a builder/reviewer
agent id before dispatch ever happens, backed by a five-row evidence table. Re-checking each row
against `development` @ `40a75da` (2026-08-10) finds it **partially stale**:

| # | Issue's claim | Holds today? | Evidence |
|---|---|---|---|
| 1 | `utils/py/marathon_drive.py:876` dies with `"...must start with claude/codex/agy/aider"` | **NO — fixed** | The `die(...)` call is now at `utils/py/marathon_drive.py:1103`, and its message reads `"...must start with claude/codex/agy/aider/pi"`. The `route_agent` closure at `:1097-1103` has a `elif agent_id.startswith("pi"): os.environ["PI_AGENT"] = agent_id` branch (`:1102`) that returns before the `die`. `git blame` attributes both lines to `66d2945f` (2026-08-09, "feat(GH-451): route Pi builders through Python marathon (#452)"), landed on `development` with no open PR — this is merged, not in flight. |
| 2 | `relay-automation/marathon-drive.sh:780` dies identically | **YES — still holds** | `relay-automation/marathon-drive.sh:783`: `*) die "agent '$1' not recognized — must start with claude/codex/agy/aider" ;;` — unchanged, no `pi` branch. This file carries the `# FROZEN (GH-308)` banner at `:2-3` and PR #452 did not touch it (confirmed via `git show --stat 66d2945f`). |
| 3 | `relay-automation/marathon-agent.sh` has no Pi branch | **NO — fixed** | `relay-automation/marathon-agent.sh:36` declares `pi_agent="${PI_AGENT:-}"`, and `:65-68` dispatch `"$pi_agent") ... exec "$HERE/pi-turn.sh" ;;`, matching the shape of the other four branches (`:49-64`). `git blame` attributes `:65-68,70` to the same `66d2945f` commit. |
| 4 | `test/marathon-drive.sh` has zero references to `pi-turn` / `PI_AGENT` | **YES — still holds** | `/usr/bin/grep -c 'pi-turn\|PI_AGENT\|pi_agent' test/marathon-drive.sh` → `0`. PR #452 added Pi coverage instead to `test/pi-turn.sh` and `test/test_python_layer.py` (`git show --stat 66d2945f`) — neither is the file this issue's own acceptance criterion names. |
| 5 | `relay-automation/pi-turn.sh` and `utils/py/pi-turn.py` exist | **YES — still holds** | `relay-automation/pi-turn.sh` — 15,534 bytes. `utils/py/pi-turn.py` — 9,008 bytes. Both present, both executable shims from GH-295. |

**Why this happened without anyone lying:** #414 (filed 2026-08-03, updated 2026-08-05) and #451
(filed 2026-08-08) were opened four and three days apart, targeting overlapping code with different
framings — #414 as "the router rejects Pi", #451 as "route Pi through the Python-default path". #451
shipped first (PR #452, 2026-08-09) and is still open on GitHub with ROADMAP.md's line for it
unreconciled against the merge. #414 was never updated to reflect that its own evidence had partly
been overtaken. This doc is the reconciliation.

**What is genuinely still missing**, confirmed above: a regression case in `test/marathon-drive.sh`
naming Pi (row 4), and an explicit note that the Bash twin diverges from Python on purpose rather
than by oversight (no such note exists near either `route_agent` today — checked both files). Row 4's
gap is real and reachable, not cosmetic: `relay-automation/marathon-drive.sh` still runs by default
when `XYZ_PYTHON` is explicitly set to `0` or empty (`relay-automation/marathon-drive.sh:9`,
`if [[ "${XYZ_PYTHON-1}" == "1" ]]`), so an operator in that mode hits the unfixed Bash rejection.

## Acceptance

*Copied verbatim from [issue #414](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/414) (`## Acceptance`), fetched 2026-08-10. Deviations, if any, are recorded below this block.*

- [ ] `utils/py/marathon_drive.py`'s `route_agent` accepts a `pi*` agent id and exports `PI_AGENT`, and its rejection message lists pi alongside claude/codex/agy/aider.
- [ ] `relay-automation/marathon-agent.sh` dispatches a `PI_AGENT` match to `pi-turn.sh`, matching the shape of the existing four branches.
- [ ] `marathon-drive --builder pi --reviewer agy --dry-run` reaches the binary probe and the render step instead of dying at agent-id validation.
- [ ] A regression case in `test/marathon-drive.sh` pins the Pi lane, and is observed failing against the current code before the fix.
- [ ] The frozen Bash twin's divergence is recorded explicitly (a comment or a parity-test exception) rather than left as undocumented drift between the two drivers.

## Acceptance — deviations from the issue

None. Every criterion is carried verbatim, unreworded, unreordered.

**Status of each against code on disk today** (not a deviation — the wording above is untouched;
this is what a builder should know before starting):

1. **Already satisfied.** `route_agent` accepts `pi*` and exports `PI_AGENT`; the rejection message
   lists `pi` (`utils/py/marathon_drive.py:1097-1103`). Landed in `66d2945f` (2026-08-09).
2. **Already satisfied.** `relay-automation/marathon-agent.sh:65-68` dispatches `PI_AGENT` to
   `pi-turn.sh`, matching the other four branches exactly. Same commit.
3. **Believed satisfied, not directly proven by an existing named test.** `route_agent` no longer
   dies on `pi*` (criterion 1), and `test/test_python_layer.py`'s
   `test_marathon_drive_fails_before_tick_state_when_pi_builder_binary_missing` (added in the same
   PR #452) invokes `marathon_drive.py --builder pi --reviewer agy` and asserts a *binary-missing*
   failure — which is only reachable if agent-id validation already passed. That is strong indirect
   evidence, but no test asserts the criterion's literal words ("reaches the binary probe and the
   render step") for a *present* Pi binary. Whoever fires this lane should either point at that test
   as satisfying evidence explicitly, or add a one-line assertion that removes the inference.
4. **Not satisfied.** Confirmed 0 references to `pi-turn` / `PI_AGENT` in `test/marathon-drive.sh`.
   This is the real remaining work.
5. **Not satisfied.** No comment near either `route_agent` implementation states that the divergence
   is intentional. This is the other real remaining work.

## The gap this issue does NOT close — Pi still cannot REVIEW

Added 2026-08-10 after a codex pass, because it changes what this lane is worth and neither the issue
nor the draft above says it.

Every criterion here is about `--builder pi`. **Pi as a REVIEWER is blocked independently, in two
places, and finishing all five criteria will not unblock it:**

| Path | What happens with `reviewer: pi` | Line |
|---|---|---|
| Multi-phase marathon (via `MARATHON.yaml`) | rejected at YAML validation — the driver never starts | `bin/marathon-yaml:95-96` (`/^(codex\|gemini\|agy)/`) |
| Single-lane `marathon-drive --reviewer pi` | routes fine, then dies at the reviewer-specific check | `utils/py/marathon_drive.py:1111-1112` |

That matters because the **reason** to want Pi routable is as a fallback when agy is unhealthy — and
agy failed twice on 2026-08-10 (a 900s no-CPU hang mid-marathon, then an auth pre-flight timeout that
killed a consult). A fallback *builder* does not help when the *reviewer* is what died.

**A latent contradiction found in the same pass, worth fixing alongside:** the reviewer allowlist at
`:1111` permits `gemini`, but `route_agent(args.reviewer)` runs first at `:1109` and `gemini` is not
in its accepted set (`claude/codex/agy/aider/pi`, `:1097-1103`). So `reviewer: gemini` passes the
YAML regex, then dies at `:1103` — and `:1111`'s `gemini` branch is **unreachable code**.

Precisely two sets are in play, not three: `bin/marathon-yaml:95`'s regex and `:1111`'s `startswith`
chain accept an **identical** set (`codex|gemini|agy`), so those two never disagree with each other.
The split is between that reviewer set and `route_agent`'s (`claude|codex|agy|aider|pi`), and it runs
in both directions — `pi`/`claude`/`aider` route but are refused as reviewers, `gemini` is allowed as
a reviewer but does not route. Only the second direction is dead code.

Recorded here rather than silently widened into this lane's scope: extending the reviewer allowlist
is a separate decision with its own blast radius (a reviewer that cannot be trusted to review is
worse than no fallback), and this doc's job is to say so, not to settle it.

## Litmus tests

- **A criterion already true on disk is not evidence produced by this lane.** Criteria 1 and 2 predate
  this capture by a day (they landed 2026-08-09; this doc is dated 2026-08-10) via a different issue.
  A builder must not claim credit for them in this lane's commit — they were verified, not built here.
- **The regression case (criterion 4) must prove it is a real guard, not a tautology.** Since the
  underlying routing behavior already works, a naive "assert pi routes" case would pass whether or not
  it is wired correctly. It must be checked to fail against the pre-`66d2945f` shape of
  `marathon_drive.py` (e.g. by temporarily reverting the `elif agent_id.startswith("pi")` branch
  locally) before being trusted as a pin, mirroring criterion 4's own "observed failing against the
  current code before the fix" language — here read as "before *this specific* code existed", since
  the router fix predates the test.
- **A green `validate.sh` proves nothing about criterion 5.** It is a documentation criterion inside
  code comments; the gate does not read prose. A reviewer must check by reading, the same shape GH-392
  and GH-358 both used for their non-mechanically-gatable criteria.

## Reversibility & blast radius

**Write-set analysis — this is the load-bearing part of this doc.**

- **`relay-automation/marathon-drive.sh` is a FROZEN TWIN** (`test/gh308-frozen-twin-guard.sh:23`,
  `TWINS` array). ANY diff to it — even a comment recording the Pi divergence — is blocked by the
  GH-308 guard unless the commit carries a `Frozen-twin-exception: relay-automation/marathon-drive.sh
  — <reason>` trailer (GH-321 format; verified against `test/gh308-frozen-twin-guard.sh`'s
  `collect_declared`/`is_frozen_path` logic, `:93-201`). This repo is phasing out Bash — `XYZ_PYTHON`
  already defaults to `1` (`relay-automation/marathon-drive.sh:9`), meaning the Bash body is the
  fallback path, not the default one — and GH-451's own non-goals explicitly ruled out touching this
  file. **Recommendation: do not touch `relay-automation/marathon-drive.sh` for criterion 5.** Record
  the divergence entirely on the Python side instead — a comment beside
  `utils/py/marathon_drive.py`'s `route_agent` (`:1097-1103`) stating plainly that the frozen Bash
  twin (`relay-automation/marathon-drive.sh`) still rejects `pi*` by design, that this is reachable
  whenever `XYZ_PYTHON` is set to `0` or empty, and pointing at GH-308/GH-451 for why. This satisfies
  criterion 5's "a comment ... rather than left as undocumented drift" without touching the frozen
  file or needing an exception trailer. **Implication for the Bash lane:** it stays asymmetric and
  four-agent-only, on purpose, indefinitely, until Bash is retired outright — this lane does not close
  that gap, it only stops the gap from being silent.

- **`relay-automation/marathon-agent.sh` is NOT a frozen twin** (absent from the `TWINS` array) and
  already carries its `PI_AGENT` branch as of `66d2945f` — this lane's remaining scope does not need
  to touch it. Stated plainly for the general case anyway, since the instructions ask: this file is
  `exec`'d via `RELAY_AGENT` dispatch on **every turn** of a running marathon (`case "$me" in
  "$claude_agent") ... "$pi_agent") ... exec "$HERE/pi-turn.sh" ;; ...`). Editing it AS a live
  marathon phase is **unsafe in general** — a phase whose builder turn modifies this file creates a
  self-referential dependency: the very next turn (the reviewer's) re-`exec`s the file it was just
  changed by, with no isolation between "the edit that just landed" and "the mechanism the running
  turn depends on" to route itself. A broken edit strands the run mid-turn rather than failing before
  it starts. Moot for this specific lane (no further edit to this file is needed), but any future
  change to it should land via a relay or a direct commit outside a live marathon, not as a marathon
  phase that dispatches through the very file it is changing.

- **Overall blast radius: minimal.** The remaining real work is a test addition
  (`test/marathon-drive.sh`, test-only, no runtime behavior change) plus one explanatory comment in
  `utils/py/marathon_drive.py` (no behavior change — `route_agent`'s logic is untouched). Neither
  frozen twin nor the live dispatcher needs editing. Fully revertible by reverting one commit.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "grep_absent", "path": "test/marathon-drive.sh", "pattern": "PI_AGENT" }
  ],
  "artifacts":     ["test/marathon-drive.sh", "utils/py/marathon_drive.py"],
  "artifacts_new": [],
  "remediation":   { "source": "issue #414", "criteria": "pin a Pi-builder regression case in test/marathon-drive.sh and record the frozen Bash twin's Pi divergence explicitly on the Python side — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
  "lanes": { "agy_safe": ["test/marathon-drive.sh"], "orchestrator_only": ["utils/py/marathon_drive.py"] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `grep_absent` reports `landed` — the fix
still required — while `PI_AGENT` is absent from `test/marathon-drive.sh`. Verified 2026-08-10 with
`/usr/bin/grep -c` (bare `grep` is hook-rewritten in this environment and can false-negative): `0`
occurrences. Once the regression case lands, the probe stops firing and the lane is no longer
fireable on that criterion — the intended behaviour.

`utils/py/marathon_drive.py` is scoped `orchestrator_only` rather than `agy_safe` because it is core
driver logic shared by every marathon run, even though this lane's change to it is comment-only.

## Provenance

Filed as issue #414 2026-08-03, from GH-295's Pi-shim shipment. Captured to `2-WORKING` 2026-08-10 for
release 0.3.0 Nightwatch. Re-verified against `development` @ `40a75da` rather than trusted as
written — two of the issue's five evidence claims no longer hold because GH-451/PR #452 (`66d2945f`,
merged 2026-08-09) independently shipped the Python-side routing three to six days after #414 was
filed. GH-451 itself is still open on GitHub and ROADMAP.md's line for it is unreconciled against that
merge — a separate, smaller cleanup this doc surfaces but does not fix (out of scope: this doc's
instructions are to author #414 only, touch no other file).
