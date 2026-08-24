# Standard Operating Procedure (SOP): Testing Campaigns, Benchmarks, and Artifact Provenance

> **Scope & Relationship to `AGENTS.md`**:
> - **`AGENTS.md`** owns repo-wide behavioral governance, core principles (*Verified Beats Plausible*, blast radius sizing, reversibility scale), marathon load rails, role splits, and push boundary gates.
> - **`SOP.md` (this file)** is a specialized, tactical execution procedure specifically for **testing campaigns, ATE variation matrices, and benchmark telemetry provenance** (`TESTS-RESULTS/`).
> - **Overlap (~25%)**: This SOP references and enforces `AGENTS.md` invariants (standalone clone isolation GH-564, githooks/pre-push gates, and committed `.jsonl` telemetry GH-430) within its step-by-step campaign workflow rather than redefining general repository policy.

This document outlines the standard operating procedure for designing, executing, verifying, and committing evidence from automated testing campaigns, harness evaluations, and ATE variation matrices.

> Picking a skill to run a step of this SOP (e.g. a diagnostic pass before a campaign, or a relay
> to synthesize a fix)? See `ARCHITECTURE.md` → "Skills Index" for the full one-line inventory.

---

## 1. Governance & Principles

- **Verified Beats Plausible (Rule 6 / GH-430):** Any model grading, performance claim, or architecture recommendation must be backed by retained, committed telemetry (`error_log.jsonl` / `*.jsonl`) in `TESTS-RESULTS/`.
- **Full Clone Isolation (GH-564):** Never run destructive suites, resets, or multi-hour variation runs in the primary working tree or a linked worktree. Always provision a standalone clone (e.g. `../XYZ-forge-<topic>`).
- **Process Group Containment:** All spawned runners must use process-group session isolation (`setsid`) and PGID-targeted cleanup (`SIGTERM` -> `SIGKILL`) to prevent zombie child processes.
- **Auto-File Confirmed Defects:** When a campaign, probe, or soak produces a finding with a deterministic reproduction, the agent **files the GitHub bug issue immediately — without waiting to be prompted**. Filing an issue is easily reversible and non-destructive (close it if wrong), so asking permission first adds latency without adding safety. Only ambiguous or attribution-unclear findings get *offered* ("want this filed?") rather than silently held. Every filed issue carries the reproduction command, evidence links, and a fix sketch so it is marathon-ready. First applied 2026-08-23: the Gen 3.5 soak findings (#174/#177) became #180–#184 without prompting.

---

## 2. Standard Workflow Lifecycle

```
[1. Intake / PDDA Doc]
        │
        ▼
[2. Standalone Clone Setup] ──> (bash githooks/install.sh)
        │
        ▼
[3. Local Gate Qualifying]  ──> (./validate.sh)
        │
        ▼
[4. Grid Configuration]     ──> (utils/ate/variations.<name>.yaml)
        │
        ▼
[5. Campaign Execution]     ──> (python3 utils/ate/scripts/run_variations.py)
        │
        ▼
[6. Supervision & Triage]   ──> (checkin.py / local LM Studio classifier)
        │
        ▼
[7. Results Ingestion]      ──> (TESTS-RESULTS/YYYY-MM-DD+GH-<n>/)
        │
        ▼
[8. Registry & Closeout]    ──> (HARNESS-MODELS-REGISTRY.md & PR)
```

---

## 3. Step-by-Step Instructions

### Step 1: Intake & Working Doc
1. File the tracking GitHub issue.
2. Scaffold the active doc in `PROJECT/2-WORKING/GH-<n>-<SLUG>.md`.
3. Add the ledger row to `ROADMAP.md` and sync via `python3 utils/py/releases_app.py roadmap sync`.
4. Verify document hygiene with `utils/pdda/pdda.sh run`.

### Step 2: Isolated Full Clone Provisioning
```bash
git clone . ../XYZ-forge-<topic>
cd ../XYZ-forge-<topic>
bash githooks/install.sh
```

### Step 3: Local Gate Qualification
Before launching a campaign or spending API tokens:
```bash
./validate.sh
bash utils/fuzzing/fuzz-loop.sh
```
Ensure 100% of test suites pass before proceeding.

### Step 4: Configure Matrix & Telemetry
Define the variation matrix in `utils/ate/variations.<name>.yaml`:
- Always use `{harness_root}` in `command_template` for script paths.
- Ensure the runner emits structured telemetry fields (`duration_ms`, `turn_count`, `prompt_tokens`, `completion_tokens`, `tokens_source`).
- **Diagnostic Probes:** Set `expects_edits: false` on diagnostic grids that read/report without modifying the working tree (prevents false `no_edit` classifications).

### Step 5: Execute Campaign with Supervision
Provision a disposable scratch repository outside the codebase:
```bash
SCRATCH="${TMPDIR:-/tmp}/ate-scratch-<name>"
mkdir -p "$SCRATCH" && git -C "$SCRATCH" init -q

python3 utils/ate/scripts/run_variations.py \
  --repo "$SCRATCH" \
  --variations utils/ate/variations.<name>.yaml \
  --lmstudio-model "google/gemma-4-31b-qat" \
  --minutes 60 \
  --log-file "$SCRATCH/error_log.jsonl" \
  --test-name "<topic>-grid" \
  --allow-destructive-reset
```

### Step 6: Monitor & Inspect Drift
Supervise the running loop at 5-minute intervals using `checkin.py`:
```bash
python3 utils/ate/scripts/checkin.py --log "$SCRATCH/error_log.jsonl"
```
Monitor failure clusters, category distributions (`auth_failure`, `config_error`, `env_failure`), and throughput. If a valid defect is identified:
1. **File a GitHub tracking issue immediately (auto-file — §1; do not wait to be prompted).** Ambiguous findings: offer to file rather than holding them silently.
2. If straightforward, dispatch to DeepSeek Harness (`dsh` -> OpenRouter -> `deepseek-v4-pro`) in a clean standalone full clone (GH-564) to synthesize a fix and regression test.
3. If complex, record findings on the issue for architectural planning.

### Step 7: Commit Artifact Receipts
Store the campaign output in `TESTS-RESULTS/`:
1. Create `TESTS-RESULTS/YYYY-MM-DD+GH-<issue-number>/`.
2. Copy `error_log.jsonl` and raw baseline measurements into the folder.
3. Author a `SUMMARY.md` documenting duration, total runs, variation distribution, and key findings.

### Step 8: Update Registries and Open PR
1. Record findings and policy updates in `HARNESS-MODELS-REGISTRY.md`.
2. Update the status table in `PROJECT/2-WORKING/GH-<n>-<SLUG>.md`.
3. Update GitHub issue with summary notes.
4. Verify pre-push gates (`test/gh308-frozen-twin-guard.sh --check --staged`).
5. Commit, push branch, and open PR against `development`.

---

## 4. Opinionated SOPs (XYZ-maintainer defaults — optional downstream)

> **Who these are for:** These conventions exist to help the **XYZ maintainers** with our own
> development flow on this repository. They are **not** part of the harness contract.
> **Public users and downstream forks are free to disable them**, instruct their own LLM
> maintainers to ignore them, or write a script that strips this section on pull from upstream.
> Nothing in the codebase enforces them.

- **Primary checkout stays on `development`.** The local device's GitHub-mapped primary working
  tree (this folder) is always kept on the `development` branch. Feature work does not happen
  here — see the next rule.
- **Express-to-development is explicit; everything else gets a fresh full clone.** The user must
  explicitly ask for an express commit + push into `development` for critical work. When the user
  does not say so, the LLM begins new work by provisioning a **new local full-clone folder**
  (`git clone . ../XYZ-forge-<topic>` — a full clone, *not* a git worktree, per GH-564), then
  follows the standard path: `feat/`- or `fix/`-prefixed branch → PR into `development`.
