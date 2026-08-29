# MACHINE-CONTRACTS.md

The reference for the machine-readable contracts that carry state across the Jog ↔
Swarm-Preflight ↔ Marathon seam — and the version/deprecation policy that governs them.
Field lists here are normative: producers and loaders are pinned by
`test/gh280-jog-marathon-adapter.sh` (contracts + executor), `test/gh290-ate-variation-grid.sh`
(hostile-input matrix), and the golden conformance fixtures. If this file and the code
disagree, the code is the bug *and* the doc is the bug — fix both in the same PR.

Why these exist (GH-280): a supervisor must never parse logs, prose, or fenced JSON to learn
what a run did. Every cross-boundary fact travels as a schema-stamped JSON artifact with
explicit nulls; anything not in the artifact is unknown, not inferred.

## Common rules (both contracts)

- **JSON, UTF-8, one artifact per run.** The `schema` field is the first key checked; a
  consumer that does not recognize it refuses (exit-shaped, named reason) — it never
  "best-effort parses."
- **Explicit nulls.** A key that has no value for this run is present with `null`, not
  omitted. Absent-key and null must never mean different things.
- **Atomic writes.** Artifacts land via write-temp-then-`os.replace` so a reader never sees
  a torn file.
- **Records, not verdict overrides.** A receipt documents what happened; it never changes the
  producing process's own exit code or retry behavior. Consumers own their decisions.
- **Paths are data, not parsers.** `argv` is a real array (never a shell string to eval or
  word-split); env entries are a map.
- **Never the reverse direction.** Nothing downstream writes these artifacts except their
  single producer. Consumers read and re-record pointers (e.g. Jog's ledger stores
  `result_path`), never rewrite the artifact.

## Contract A — `swarm-preflight/marathon-invocation@1`

**Producer:** `utils/py/swarm_preflight.py` → `build_marathon_invocation_artifact()`, written
as `marathon-invocation.json` beside the readiness packet.
**Consumer:** Jog's marathon executor (`utils/py/jog_run.py` → `load_marathon_invocation()`),
which validates then dispatches argv[0] with `env` applied.

What it answers: *"here is the exact drive command a supervisor may run for this ready
issue."* It is a **suggestion, not an authorization** — a supervisor with its own policy
(e.g. mandatory explicit reviewer, GH-280 G1/G2) still enforces it after loading.

| Field | Meaning / consumer rule |
|---|---|
| `schema` | `"swarm-preflight/marathon-invocation@1"` — exact match or the loader refuses |
| `generated_at` | UTC stamp |
| `harness_root` / `harness_home` | harness repo root; `.xyz`-prefixed drives make home the vendored `.xyz` (GH-279 #2) |
| `target_root` | repo the work lands in (root or consumer repo) |
| `drive_command` | absolute path of the drive executable |
| `argv` | argument array; `argv[0]` must be absolute and executable (loader refuses otherwise); embeds `--result-file` beside the packet |
| `env` | `XYZ_HARNESS_CONTEXT=swarm`, `XYZ_SESSION_ID=<slug>`, `RELAY_WORKTREE_ISOLATION=1` |
| `issue` | GH issue number as string, or `null` |
| `phase` / `lane` | slug; supervisors adopting per-issue `--phase-id` key off `phase` |
| `artifacts` | declared artifact paths the builder must land |
| `gate` | the gate command string |
| `builder` / `reviewer` | suggested agents (codex/agy default, GH-212) |
| `base_ref` | branch the run must start from |
| `packet_dir` / `packet_path` | readiness packet location (must resolve) |
| `result_path` | where Marathon will write its result receipt |

## Contract B — `marathon-drive/result@1`

**Producer:** `utils/py/marathon_drive.py` → the single terminal writer
(`write_terminal_result`, registered on-exit; armed by `--result-file`, keyed by
`--execution-id`).
**Consumer:** Jog's projection (`load_marathon_result()` → `jog_project_marathon_outcome()`)
and landing (`jog_land`, whose verification re-checks GitHub truth before trusting any of it —
GH-300 B1).

What it answers: *"here is exactly how this execution terminated, with every identity field
needed to decide what happens next."* Exactly one receipt per terminal exit — including
pre-dispatch refusals.

### Outcome vocabulary (closed set)

| outcome | exit code | meaning |
|---|---|---|
| `approved` | 0 | built, reviewed, gate green |
| `lock-contention` | 1 | driver lock held by a live peer |
| `refused` | 2 | pre-dispatch policy refusal (nothing dispatched) |
| `parked` | 8 | attempt cap reached; lane parked |
| `post-approve-failed` | 9 | approved, then a post-approval step failed (`approval_preserved: true`) |
| `interrupted` | ≥128 | signal death |
| `crashed` | (exception) | driver raised an unhandled exception |
| `escalated` | other | deliberate escalation (gate red, relay failure, no progress, tick failure, cap/close mismatch…) |

Notes pinned by review (#291 correction, accepted):
- There is **no `already-landed` outcome.** Preflight's already-landed signal parks at the
  *queue* level without a receipt; inside a drive, a satisfied lane reports
  `outcome: approved, reason: already-satisfied` (GH-274).
- `reason` is a machine token first (`already-satisfied`, `pre-advance-failed`,
  `no-progress`, `cap-or-close-mismatch`, `relay-failed-before-gate`, `timeout-no-artifact`,
  `tick-command-failed`, …) with the human-readable mapping as fallback.

### Receipt fields

`schema`, `execution_id`, `generated_at`, `outcome`, `reason`, `exit_code`,
`approval_preserved`, `issue` (derived, may be `null`), `phase`, `lane`, `token`,
`attempt {count, max}`, `builder`, `reviewer`,
`target_repo {path, origin_url}`, `base_branch`, `head_branch`, `head_sha`,
`branch_redirect`, `gate {cmd, result: green|red|not-run, exit, receipt_path}`,
`acceptance {checked, unmet_count}`, `pr {number, url, state}` (all-null when no PR —
`pr_note` carries the failed-publication reason), `relay_status`, and
`timestamps {started_at, finished_at}`.

Ownership split (GH-280 authority model): Marathon exclusively owns everything in this
receipt — execution attempts, Tick history, builder/reviewer turns, acceptance, gates,
branch/commit state, and PR identity. Jog owns the queue row, leases, the operator-facing
park/land decision, and its *own* execution ledger under `.tick/jog/<gid>/`
(`jog/execution-state@1`), which records pointers (`packet_dir`, `result_path`) and
projections — never a second copy of Marathon's truth.

## Version negotiation and deprecation policy

Both contracts are integer-versioned (`@1`). There is no prior version; "prior" is defined
forward by this policy. Readers refuse unknown versions **by design** — a reader that
guessed a newer artifact's shape would be silently mis-projecting state.

A version change ships as a three-step ladder, each step gated by the suites above and
landed in its own PR:

1. **Widen readers.** Loaders grow an explicit accept-set (e.g. `{"@1", "@2"}`). Old
   artifacts keep working; new ones become readable. No producer changes yet.
2. **Flip producers.** Producers stamp `@2`. Because every reader in the repo already
   accepts `@2`, the flip cannot orphan a consumer.
3. **Narrow readers** — no sooner than the next release cycle after step 2 — to `{"@2"}`
   only. This is the deprecation window's far edge: bounded by release cycles, not by
   "whenever," and it lands only when the golden fixtures and the hostile-input matrix have
   both run against the surviving version.

Rules for what `@N+1` may contain: **additive optional fields, or nothing.** Renames, removals,
type changes, and semantic redefinitions of an existing field require a new contract name,
not a version bump — a consumer must be able to read `@N+1` with its `@N` logic plus
null-tolerant accessors for fields it doesn't know.

Out-of-band drift is a defect: any consumer caught parsing `marathon-invocation.txt`,
logs, prose, or fenced JSON to obtain a fact these contracts carry is failing the
boundary-regression guard (#291 Scope 3, marathon-executor path; the legacy
`--executor relay` path is the declared exception until its Phase-5 removal).

## Provenance

- Producers: `utils/py/swarm_preflight.py` (Contract A), `utils/py/marathon_drive.py`
  (Contract B).
- Loaders/validators: `utils/py/jog_run.py` (`load_marathon_invocation`,
  `load_marathon_result`, `jog_verify_pr_before_merge`).
- Pinning suites: `test/gh280-jog-marathon-adapter.sh`, `test/gh290-ate-variation-grid.sh`
  (both registered in `validate.sh`).
- History: GH-280 (introduction), GH-292 (F1–F3 durability fixes), GH-300 (verified
  pre-merge auto-merge, locked retry verbs), #291 (this reference + policy, Scopes 1+5).
