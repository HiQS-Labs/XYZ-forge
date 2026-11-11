# GH-1422 verification and requirement map

Base: `966290ddd8b69fcfd49a9df5e123b118befcd6e1`. Candidate content hash is in provenance.jsonl.

## Measured controls

`wc -c AGENTS.md`: 42,768 bytes before; 27,756 after (15,012 fewer; 5,012 bytes headroom).
A manual Python byte predicate `0 < len(data) <= 28000 < 32768` failed on the original
and on empty bytes, and passed on the candidate. The probe reads baseline with
`git show <base>:AGENTS.md`, candidate with `Path('AGENTS.md').read_bytes()` and hashes
both with SHA-256. No test suite or gate was added.

`git ls-files -z` filtered by filename `AGENTS.md` / `AGENTS.override.md` returned only
root `AGENTS.md`. Default tracked root-to-directory project chains therefore total 27,756
bytes. User/global config, custom fallback filenames, untracked overrides and files in an
external parent project are outside this claim. Links do not auto-load their destinations.

Manual relative-link probe extracted Markdown targets, asserted local files exist and matched
fragments to heading slugs. All eight local targets passed. Remote references were retained or
archived below; no claim of authenticated HTTP validation is made.

Consumer smoke: read ROUTER startup step 2 → full candidate AGENTS; critical danger rules,
authorization, required-read routing and conflict order are retained. Adjacent path: default
nested-directory discovery has no additional tracked instructions and stays under the cap.

## Original-to-current requirement map

All operative rules remain in AGENTS.md. No new destination document or nested instructions
were created. This table maps compressed groups; unmodified groups are enumerated afterward.
The existing canonical documents provide detailed rationale, not automatic instruction loading.

| Original section/rail | Current location and retained obligations |
|---|---|
| What this file owns / reconciliation and maintainer SOP | Same section: local writer, hosted-active refusal/override, no task views, drift check, one-branch authorization |
| Operating principle 6 | Same heading: same-PR committed provenance; red controls; no new suites; reject empty evidence; flaky-suite tier behavior; network permission per use; two-attempt blocker trigger; scoped proportionate rigor |
| No new tests | Same rail: no suite/registry/gate/guard/lane/runner/telemetry stage or meta-test; truthful existing-suite changes only; manual receipts; superseded #815/#816/#817/#819 |
| Marathon work selection | “Prove the harness”: one named active marathon; comparable-value selection rationale; real needed work only; no synthetic load; honest idle and failure reporting |
| RELEASES DB | Same rail: two subsystems/one CLI; pickup rows; legacy sync no-op; no hand edits; required FAQ and conflict resolver |
| Local gate / hosted CI | Same rail: per-clone hooks across branches/worktrees; commit versus push boundary; parallel sizing; sequential qualifying ci-local; local reconciliation and pre-promotion full run; bypass disclosure/limited draft authority; actual SHA evidence |
| Undo experiments | “Never restore committed tree state”: protect peers, copy before experimenting, recovery snapshot is not authorization |
| Scratch | Same rail: temp/outside repo only; deliberate promotion; root-scratch accidental publication risk |
| Frozen Bash | Same rail: twelve named Python owners; fallback-only Bash; staged and hosted guard; per-file named exceptions; freeze-establishing/historical exceptions; no new Bash and scoped exemptions |
| Builder/orchestrator | Same rail: Claude never default builder; explicit usage acknowledgement; unavailable defaults require asking; inspect emitted PR base/scope/final gate; independent QA receipts separate |
| Subagent containment | Same rail: modifying Claude agents need worktree isolation, read-only exempt, harness rtl isolation, committed inputs, lock-dir friction; shared Git state; unsandboxed suite requirement |
| Disposable full clone | Same rail plus mandatory WORKTREE-SAFETY section 12 read: no valued-clone/worktree suites; identity bracket; drift invalidates run; same-width controls; serial pass insufficient |
| Use-boundary path validation | Within disposable clone rail: nonempty/resolved/contained/type checks in each receiving function; no lexical-only or strict-mode substitute; existing require_fixture gap retained |
| Invocation audit variants | Within disposable clone rail: Bash-only detectors miss Python, actual GH-195 failure retained, trace repeatable write evidence before speculative processes |
| Local macOS / Ubuntu | Same rail: local platform verification required, retired suites excluded, Ubuntu advisory except Linux claims, self-reported local green insufficient for promotion |
| Branch creation / development | Same two rails: interactive request requirement and explicit carve-outs, driver guard, all work from/to development, periodic promotion, stale-branch handling |
| Branch rename | Same rail: rename deletes ref/closes open PR; rename before PR or open replacement and pointer-comment old PR |

Unmodified: purpose; Danger list and warranty; startup/required-read references; standing AI
sharing authorization and outer-loop #1328 boundaries; runtime default; operating principles
1–5 and 7–8; sandboxed branch mutation guard; canonical owner pointers and PDDA distribution
policy; PARKED exception; HQ cross-repo routing; costly kernel surfaces; promotion's five
exact-commit/quiet-window gates; queue/attempt limits; Aider configuration, format and alias
resolution rules; conflict order. Existing heading names remain intact.

Historical links replaced by compact issue references in AGENTS (preserved here):
- https://github.com/HiQS-Labs/XYZ-forge/issues/831
- https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/216
- https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/217

## QA and gates

Plan relay: Approved, reviewed `5b6db4820f275ba293dc245f4e2413a114ee5c8e`.
Docs gate passed (exit 0, zero errors, 99 existing backlog warnings); final omission review Approved at `d53a88d60` after restoring the same-PR provenance boundary (round 2). Final publication reruns the push gate.

## Edit verdicts and lesson admission

AGENTS compression: helped byte-budget compliance (base fails, candidate passes).
Policy-behavior equivalence: not measured by runtime experimentation; independent textual QA required.
Lesson verdict: NO_ENTRY — byte reduction proves this acceptance criterion, not a new general
lesson beyond the documented instruction budget.

## Post-consult correction

Current count: 27,812 bytes, 4,956 bytes headroom. See [consult-corrections.md](consult-corrections.md)
for accepted/rejected findings and fresh exact-content verification; prior counts above are historical.
