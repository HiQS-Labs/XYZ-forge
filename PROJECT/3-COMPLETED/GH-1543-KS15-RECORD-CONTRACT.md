---
gh_issue: 1543
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1543
title: "kickstart(KS-15): versioned run-record contract, atomic appends, redacted snapshot and checkpoint helper"
status: Complete
created: 2026-11-20
updated: 2026-11-20
owner: operator
goal: "Define the kickstart v1 run-record grammar, atomic append primitive, redacted snapshot, and branch checkpoint helper in run_record.py and kickstart/SKILL.md so KS-04, KS-06, KS-08, KS-09, KS-13, and KS-20 share one canonical parser and writer."
doc_type: feat
complexity: 2
risk: 1
effort: 2
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Revised plan for Codex Plan QA round 3 (mandatory `--primary` identity + pre/post-switch target-branch symlink confinement) (addressed F1 lock/in-lock validation, F2 checkpoint confinement/retry, F3 evidence contract, F4 parser precedence & disposition semantics, Nit CHANGELOG policy). | Run Codex Plan QA round 2 (`relay-system/2026-11-20/gh1543-plan-qa.md`). |

## Problem

Arc #1541 (adjudication U1, U10, U12, U16) requires the kickstart run-record contract to exist before KS-04 (`kickstart_status.py`), KS-06 (amendment application), KS-08 (killed-landing recovery), KS-09 (pinned `LANDING_CLONE`), KS-13 (final-QA invalidation), and KS-20 (interruption recovery). Today, run records are free-form Markdown with no versioned line grammar, no atomic append lock (risking torn writes or duplicate IDs on crash or parent/child contention), no standard redaction pass (run-1 publication #1542 hit stray `</content>`/`</invoke>` tags and local paths), and no confined checkpoint push helper for run-record branches.

## Requirements (from #1543 / #1541 KS-15, U1, U10, U12, U16)

1. **Versioned v1 grammar & unambiguous parser contract:**
   - **Headers:**
     - `RUN-RECORD-VERSION: 1` (optional parenthetical comment allowed after `1`). Mandatory; missing, non-`1`, or duplicate `RUN-RECORD-VERSION:` header is a validation error.
     - `LANDING_CLONE: <path>` (optional parenthetical comment allowed after path). Duplicate header or empty `<path>` is always a validation error; `--require-landing-clone` enforces presence on active run records (historical run-1 baselines may omit it).
   - **Event lines** (optional leading `- ` markdown bullet tolerated so Progress-log list entries parse identically to bare lines):
     - `OPERATOR_AMENDMENT: <ID> <ISO-UTC-TS> <text>` — `<ID>` matches `[A-Za-z0-9._-]+`, `<TS>` matches `YYYY-MM-DDTHH:MM(:SS)?Z` (or historical `YYYY-MM-DDT~HH:MMZ`; `append` always emits strict `YYYY-MM-DDTHH:MM:SSZ`), `<text>` must be non-empty and cite an operator turn (case-insensitive `operator turn`, `operator comment`, or `operator decision`).
     - `PARENT_NOTE: <ID> <ISO-UTC-TS> <text>` — same ID/TS format, non-empty text.
     - `INTERVENTION: <ID> <ISO-UTC-TS> <text>` — same ID/TS format, non-empty text.
     - `APPLIED: <ID> (?:→|->) <rest>` — **Reserved-word precedence:** inspect the first whitespace-delimited token of `<rest>` (stripping an optional trailing `:`):
       - If it is `applied`, `superseded`, or `escalated` (exact lowercase): that token is the explicit disposition, and the remainder (after stripping an optional trailing ISO-UTC timestamp) MUST be a non-empty action/artifact/reason. Thus `APPLIED: OA-1 → escalated` with empty remainder is a **validation error** (not compact text). For `superseded`, the remainder must name a declared newer amendment ID (e.g. `by OA-2`).
       - Otherwise: compact compatibility form — disposition defaults to `applied`, and `<rest>` (minus optional trailing timestamp) must be non-empty.
       - **Repeated `APPLIED` semantics & unresolved state:** an amendment (`OPERATOR_AMENDMENT` or `PARENT_NOTE`) may receive a later `APPLIED` line ONLY if its prior disposition was `escalated` (allowing recovery from hold to `applied` or `superseded`); any `APPLIED` after terminal `applied` or `superseded` is a validation error. `parse_record` exposes `unresolved_amendments` (amendments with no `APPLIED` line OR whose latest disposition is `escalated`, each tagged with `state: "pending" | "escalated"`) so downstream consumers treat both unaddressed and escalated amendments as blocking until resolved, while separately distinguishing `escalated_amendments`.
     - `GATE: <target> [head <sha>] <route> [<Ns>|(duration not recorded)] <green|red>` (and `GATE: final-QA <sha> <route> <verdict> [(duration not recorded)] ...`, matching run-1 baseline lines).
     - `BASELINE: <summary>` (optional summary line).
   - **ID integrity:** duplicate IDs across `OPERATOR_AMENDMENT`/`PARENT_NOTE` or across `INTERVENTION`, and any `APPLIED:` targeting an undeclared amendment ID, are validation errors.
   - **Compatibility examples (retained in module docstring and SKILL.md):**
     - Explicit: `APPLIED: OA-1 → applied merged #1508 per operator decision 2026-11-20T07:00Z`
     - Superseded: `APPLIED: OA-1 → superseded by OA-2 2026-11-20T07:05Z`
     - Escalated: `APPLIED: OA-1 → escalated run held pending operator confirmation 2026-11-20T07:05Z`
     - Compact legacy: `APPLIED: OA-1 → merged #1508` (parses as `disposition="applied"`, `action="merged #1508"`)
     - Invalid reserved-word empty action: `APPLIED: OA-1 → escalated` (validation error: missing action/reason after disposition `escalated`)
2. **One canonical stdlib module & CLI**: `skills/1-hourly/kickstart/scripts/run_record.py`:
   - `validate <record> [--require-landing-clone] [--json]`: parses headers and event lines, computes `unresolved_amendments` and `escalated_amendments`, prints JSON when `--json` is passed, exits 0 if valid and 1 with diagnostics otherwise.
   - `append <record> --kind <operator-amendment|parent-note|intervention|applied|gate> ...`:
     - Uses a **persistent sibling lock file** `<record>.lock` (`os.open(..., O_CREAT | O_RDWR, 0o600)`).
     - Acquires `fcntl.flock(LOCK_EX)` **before** reading the existing record (so locking the replaced record inode cannot be bypassed by concurrent openers).
     - Inside the lock: reads the current record bytes, builds the candidate record with the formatted new line, validates the complete candidate record (including duplicate IDs, `APPLIED` targets, and terminal disposition rules), and rejects with exit 1 without writing if invalid.
     - Writes candidate bytes to a temporary file in the same parent directory, calls `flush()` + `os.fsync()`, replaces `<record>` via `os.replace()`, fsyncs the parent directory (best-effort), then releases the lock.
   - `snapshot <record> [--out PATH]`: refuses empty input (exit 1), normalizes local macOS/Linux absolute home-directory paths to `~`, redacts secret/token patterns (`ghp_`, `gho_`, `github_pat_`, `sk-`, `Bearer `, `Authorization:`), strips stray tool tags (`</?content>`, `</?invoke[^>]*>`, `</?parameter[^>]*>`), and writes atomically (temp + `fsync` + `os.replace`) when `--out` is given.
   - `checkpoint --record <path> --clone <dir> --primary <dir> --branch <branch> --dest <relpath> [--message <msg>] [--push]`:
     - **Checkout identity confinement (mandatory `--primary`):** `--primary <dir>` is **required** (missing or non-existent `--primary` refuses before any mutation). Verifies `<clone>` is a git checkout; refuses if `realpath(clone)` matches `realpath(--primary)` or the record's `LANDING_CLONE` path, if `<clone>` shares `git rev-parse --git-common-dir` with `--primary`, or if `--branch` is `development`, `main`, or `master`.
     - **Clean-tree precondition:** runs `git status --porcelain` before any branch switch or write; refuses if ANY staged, unstaged, or untracked file exists in `<clone>`.
     - **Destination path confinement (pre-switch AND post-switch write boundary):** rejects absolute `--dest` and `..` traversal. Before switching branches, if `--branch` already exists locally, inspects `git ls-tree <branch>` for `--dest` and every ancestor prefix and refuses (preserving the starting branch untouched) if any entry is a symlink (mode `120000`). After switching to or creating `--branch` and immediately before writing bytes, re-verifies that `clone_root = Path(clone).resolve()` strictly contains every existing parent component and the resolved target path; if a post-switch symlink escape is detected, switches back to the original branch/ref and refuses with zero bytes written.
     - **Scoped commit & explicit non-force push:** writes the redacted snapshot to `<clone>/<dest>`, stages ONLY `--dest` (`git add -- <dest>`), commits ONLY `--dest` when staged diff is non-empty, and when `--push` is set pushes explicitly (`git push origin HEAD:refs/heads/<branch>`, never `--force`).
     - **Retry semantics:** if the redacted snapshot is unchanged (no new commit needed) and `--push` is set, checks whether `origin/<branch>` is missing or at a different SHA than `HEAD` and pushes the existing unpushed commit; if already synced, exits 0 as an idempotent no-op.
3. **Runbook update**: add a concise v1 Run Record Contract subsection to `skills/1-hourly/kickstart/SKILL.md` documenting the grammar, initialization header (`RUN-RECORD-VERSION: 1`, `LANDING_CLONE:`), and `run_record.py` subcommands as the single parser/writer.
4. **Verification**: manual checks recorded under `TESTS-RESULTS/2026-11-20+GH-1543/` with `provenance.jsonl`. No new test suite (GH-831).

## Recon (base `6270a2b5d`)

- `skills/1-hourly/kickstart/scripts/` currently contains only `build_queue.py` (256 lines; writes `--out` directly at `build_queue.py:248-249`). `prior_art_recon.py --query run_record` found 0 matching modules, PRs, or issues.
- `utils/ci-route.sh:62-69` (`is_docs_surface`) routes `skills/1-hourly/kickstart/**` as `docs` (tier 1 -> `utils/pdda/pdda.sh run`).
- Existing `kickstart/SKILL.md:151-156` defines completion evidence (PR URLs, SHAs, gates, independent review); this contract supplies structured record parsing/writing only and does not claim delivery on its own.
- Existing run-1 published baseline lines (#1542) and active run-2 record (`temp/kickstart-2026-11-20-ks1541.md`) live outside this isolated task clone; exact anonymized sample fixtures matching their line shapes will be saved inside `TESTS-RESULTS/2026-11-20+GH-1543/inputs/` for repeatable verification.

## Preflight Bet Check

- **Outcome sought:** Every downstream kickstart script (KS-04, KS-06, KS-08, KS-09, KS-13, KS-20) parses and updates the run record through one v1 contract without torn writes, ID races, secret/path/tag leaks, or checkout escapes.
- **Smallest viable bet:** One stdlib-only Python module/CLI `skills/1-hourly/kickstart/scripts/run_record.py` plus a concise contract section in `skills/1-hourly/kickstart/SKILL.md`.
- **Non-goals:** No database, no daemon, no `kickstart_status.py` (KS-04), no `build_queue.py` template edits (KS-03), no live run-2 checkpoint publication (KS-15 acceptance stays uncredited until run 2), no new test suite (GH-831).
- **Alternatives rejected:** Putting regexes directly inside `kickstart_status.py` (KS-04) and `build_queue.py` (KS-03) would duplicate grammar parsing and omit locked atomic append + redaction. Adding a JSON sidecar alongside the Markdown run record would create a dual source of truth.
- **Reversibility & blast radius:** **Easy** — additive new script + docs section under `skills/1-hourly/kickstart/`. Reverting the PR cleanly removes it with zero effect on existing skills or gates.

## PRS Rating Rationale

- **Rated:** `85/65/50/80` (`pri/sev/appeal/effort`, total `280`).
- **Priority (85):** First milestone in the operator-authorized #1541 v5 build order; blocks KS-04, KS-06, KS-08, KS-09, KS-13.
- **Severity (65):** Missing contract allowed stray tags on publication (#1542 U16), unparseable parent lines, and torn-write/split-brain risks during run 1 (operator/arc assessment).
- **Appeal (50):** Neutral default (no explicit operator appeal score).
- **Effort (80):** Small, bounded stdlib script and docs update.
- **Recurrence:** Single prior long run (2026-11-19 → 11-20) surfaced the baseline gaps documented in #1541; trend unknown (one run).

## Implementation Plan & Inline Verification

1. Create `skills/1-hourly/kickstart/scripts/run_record.py` implementing v1 grammar parsing/validation (`parse_record`, `validate_record`), sibling-locked atomic `atomic_append` (in-lock read + full-candidate validation + temp/fsync/replace + dir fsync), `redact_text`/`write_snapshot`, confined `checkpoint_record`, and CLI subcommands (`validate`, `append`, `snapshot`, `checkpoint`). -> expect `python3 -m py_compile skills/1-hourly/kickstart/scripts/run_record.py` exit 0.
2. Document the v1 Run Record Contract (including initialization headers for existing records and `APPLIED` precedence examples) in `skills/1-hourly/kickstart/SKILL.md` referencing `run_record.py`. -> expect `utils/pdda/pdda.sh run` exit 0.
3. Run recorded manual checks under `TESTS-RESULTS/2026-11-20+GH-1543/` with `provenance.jsonl`, keeping baseline absence, candidate bad-input rejections, redaction sentinel, and remote-blob checks distinct:
   - **Baseline absence:** record that `skills/1-hourly/kickstart/scripts/run_record.py` did not exist at base commit `6270a2b5d`.
   - **Candidate bad-input rejections (each records non-zero exit code + unchanged-byte SHA-256 on target file):**
     (a) `validate` and `append` reject missing/wrong version, duplicate `LANDING_CLONE`, `OPERATOR_AMENDMENT` lacking operator-turn citation, duplicate event ID, `APPLIED` targeting an unknown ID, `APPLIED: OA-1 → escalated` with empty action, and repeated `APPLIED` after terminal `applied`;
     (b) `snapshot` rejects an empty input file (exit 1);
     (c) `checkpoint` rejects omitted `--primary`, `--branch development`, `--branch main`, `--dest ../outside.md`, an existing target branch containing a symlink parent (`records -> <outside-dir>`) escaping `--clone` (preserving the starting branch untouched), an unrelated staged/unstaged file in `--clone`, and `--clone` matching `--primary` or `LANDING_CLONE` — with zero file, ref, or index mutation.
   - **Redaction sentinel (positive contamination + cleanup):** a fixture containing a local macOS/Linux home path, `ghp_FakeTokenSentinel1234567890`, and trailing `</content></invoke>` tags is matched by grep pre-snapshot, and matches zero sentinels post-`snapshot` while passing `validate`.
   - **Concurrency & retry green/smoke controls:**
     (a) `validate --json` parses saved run-1-shape and run-2-shape fixtures with 0 errors and accurate `unresolved_amendments` / `escalated_amendments` (including `escalated` → later `applied` progression);
     (b) two synchronized subprocesses concurrently appending distinct IDs both survive (zero lost/torn lines, valid final record), AND two synchronized subprocesses racing on the **same ID** produce exactly 1 success (exit 0), 1 rejection (exit 1), and a valid final record;
     (c) `checkpoint --push` in a disposable branch clone targeting a local bare remote publishes only the redacted destination — verified by reading the remote blob (`git --git-dir <bare> show refs/heads/<branch>:<dest>`) and confirming it changed from a distinct pre-publication sentinel and equals the redacted snapshot; a failed push (simulated unreachable remote) followed by retry against the real bare remote with unchanged snapshot pushes the existing unpushed commit, and a third run is an idempotent no-op.
4. Update `CHANGELOG.md` if enabled by `PROJECT/PDDA.md` / `CHANGELOG_WRITES` policy, and assess `LESSONS-LEARNED.md` (or record `NO_ENTRY`). -> expect `utils/ci-route.sh pull_request` classifies `docs` and `utils/pdda/pdda.sh run` passes.

## Acceptance Criteria Mapping

- R1 (Capability): Kickstart gains a single versioned v1 record parser, sibling-locked atomic appender, redacted snapshotter, and confined branch checkpoint helper.
- R2 (Discriminating check): Candidate bad-input gates reject every malformed/unsafe input with unchanged bytes on disk, the contamination sentinel proves redaction removes real leaks, the same-ID race proves in-lock serialization, and the bare-remote blob proves checkpoint publication.
- R3 (Proportionate cost): Single stdlib module with zero new dependencies, schemas, daemons, or test suites.

## Lessons Learned

NO_ENTRY (new capability contract; live multi-run evidence awaits run 2).
