# GH-1218 Manual Check — `rtl_turn_prompt` lessons read-back & evidence-gated writer rules

## Summary

Verified on a throwaway repository under `$TMPDIR` (`PYTHONDONTWRITEBYTECODE=1`) that:

1. **Red control (pre-GH-1218 `rtl_turn_prompt`)**: before GH-1218, `rtl_turn_prompt` never inspected `LESSONS-LEARNED.md` and emitted no lessons pointer block even when `LESSONS-LEARNED.md` was present at the turn's repo root.
2. **Fixture with 7 entries (1 superseded)**: with 7 structured entries (`Entry 1` through `Entry 7`, where `Entry 4` carries `- **superseded-by**: https://github.com/HiQS-Labs/XYZ-forge/issues/605`), `rtl_turn_prompt` appends the warn-only `[lessons learned (LESSONS-LEARNED.md) ...]` block containing:
   - the 5 newest non-superseded entries (`Entry 2`, `Entry 3`, `Entry 5`, `Entry 6`, `Entry 7`) with heading and `cue` only (narrative bodies excluded),
   - `Entry 4` skipped because it is superseded,
   - `Entry 1` omitted as the 6th non-superseded entry, reported via `+1 earlier lesson(s) omitted — see LESSONS-LEARNED.md for full history.`,
   - byte-for-byte identical prompt output across the Python path (`utils/py/rtl.py` `RelayTurnLib.turn_prompt`), the Bash fallback (`XYZ_PYTHON=0`), and `relay-automation/smallcode-turn.sh`.
3. **Silence when absent**: when `LESSONS-LEARNED.md` is absent in the throwaway repo, `rtl_turn_prompt` emits no lessons block, and the output is byte-for-byte identical across Python, Bash fallback, and SmallCode.
3b. **Out-of-order / non-monotonic ISO dates control**: with 6 valid entries where `Entry 1` carries `- **date**: 2026-12-31` and `Entry 2` through `Entry 6` carry `2026-10-02` through `2026-10-06`, `rtl_turn_prompt` selects the 5 entries with the greatest parsed `- **date**:` values (`Entry 1`, `Entry 3`, `Entry 4`, `Entry 5`, `Entry 6` in deterministic source order, with ties broken by later file position) and omits `Entry 2` (`2026-10-02`) with `+1 earlier lesson(s) omitted — see LESSONS-LEARNED.md for full history.`, identically across Python, Bash fallback, and SmallCode.
4. **Writer rules (worked example)**: demonstrated a refused candidate entry (empty `evidence` / `confounded`-only edit verdicts -> `NO_ENTRY`) and an accepted candidate entry (helped verdict + public evidence path -> structured entry).
5. **Existing suites**: `test/relay-pkg-freshness.sh` (3/3), `test/gh397-reviewer-turn-role.sh` (11/11), `test/gh681-reviewer-probe-rules.sh` (22/22), `test/gh91-relay-scratch.sh` (22/22), `test/gh304-vendored-relay-path.sh` (11/11), `test/gh609-sdlc-agent-gaps.sh` (33/33), `test/gh615-start-task-reinforce.sh` (8/8), `test/gh616-start-task-commensurate-envelope.sh` (7/7), and `test/gh308-frozen-twin-guard.sh --check --base HEAD` all pass cleanly.

## 1. Throwaway Repo Probe (7 Entries, 1 Superseded + Absent Control; Python / Bash / SmallCode Parity)

### Command

````bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 -B - <<'PYEOF'
import os, subprocess, tempfile, json, sys

root = os.getcwd()
sys.path.insert(0, os.path.join(root, "utils", "py"))
from rtl import RelayTurnLib

with tempfile.TemporaryDirectory(prefix="gh1218-probe-") as tmp:
    subprocess.run(["git", "-C", tmp, "init", "-q", "-b", "main"], check=True)
    subprocess.run(["git", "-C", tmp, "config", "user.email", "test@invalid"], check=True)
    subprocess.run(["git", "-C", tmp, "config", "user.name", "test"], check=True)
    relay_file = os.path.join(tmp, "RELAY.md")
    with open(relay_file, "w") as f:
        f.write("# Relay\nSTATUS: Open\nNEXT: agy (Builder)\n<!-- marathon-drive: task=T-1218 builder=agy reviewer=codex round-cap=5 -->\n")

    # 1. Absent LESSONS-LEARNED.md -> silent
    py_absent = RelayTurnLib(tmp, root, relay_file, "art.md").turn_prompt("agy", "T-1218", "codex")
    bash_absent = subprocess.check_output(
        ["bash", "-c", 'XYZ_PYTHON=0; source "$1/relay-automation/relay-turn-lib.sh"; rtl_init "$2" "$3" "art.md"; rtl_turn_prompt agy "$3" T-1218 "art.md" codex', "_", root, tmp, relay_file],
        text=True
    )
    sc_absent = subprocess.check_output(
        ["bash", "-c", 'source "$1/relay-automation/relay-turn-lib.sh"; ROOT="$2"; f="$3"; me="agy"; t="T-1218"; ALLOW_PATHS="art.md"; RELAY_PEER="codex"; rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"; prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"; printf "%s" "$prompt"', "_", root, tmp, relay_file],
        text=True
    )
    assert "[lessons learned" not in py_absent
    assert py_absent == bash_absent == sc_absent

    # 2. 7 entries, 1 superseded (#4)
    lessons_md = """---
title: Lessons Learned Fixture
---

# Lessons Learned

```markdown
## Template heading inside code fence
- **cue**: must be ignored because inside fence
```

## Entry 1: Oldest non-superseded lesson
- **cue**: Adding a new CLI subcommand to releases_app.py
- **lesson**: Register the subcommand in build_parser() and verify --help output in test/gh32-releases-app.sh
- **evidence**: https://github.com/HiQS-Labs/XYZ-forge/issues/501
- **confidence**: high — direct parser table dispatch
- **area**: releases
- **source**: https://github.com/HiQS-Labs/XYZ-forge/issues/501
- **date**: 2026-10-01

### Narrative
Body text for entry 1 MUST NOT appear in prompt.

## Entry 2: Second lesson
- **cue**: Tightening a verification gate or post-merge check
- **lesson**: Ship the receipt producer in the same PR as the tightened gate check
- **evidence**: https://github.com/HiQS-Labs/XYZ-forge/issues/591
- **confidence**: high — four-incident chain
- **area**: gate
- **source**: https://github.com/HiQS-Labs/XYZ-forge/issues/591
- **date**: 2026-10-02

Body text for entry 2 MUST NOT appear in prompt.

## Entry 3: Third lesson
- **cue**: Running probes during a reviewer relay turn
- **lesson**: Direct all probe outputs and TMPDIR to .relay-scratch/tmp with PYTHONDONTWRITEBYTECODE=1
- **evidence**: https://github.com/HiQS-Labs/XYZ-forge/issues/681
- **confidence**: high — verified by gh681 suite
- **area**: relay
- **source**: https://github.com/HiQS-Labs/XYZ-forge/issues/681
- **date**: 2026-10-03

## Entry 4: Superseded fourth lesson
- **cue**: Legacy manual watermark cleanup in drift brief
- **lesson**: Remove manual watermark files before re-running drift checks
- **evidence**: https://github.com/HiQS-Labs/XYZ-forge/issues/374
- **confidence**: medium — replaced by cat-file surface filter
- **area**: relay
- **source**: https://github.com/HiQS-Labs/XYZ-forge/issues/374
- **date**: 2026-10-04
- **superseded-by**: https://github.com/HiQS-Labs/XYZ-forge/issues/605

## Entry 5: Fifth lesson
- **cue**: Editing relay-turn-lib.sh or any packaged relay script
- **lesson**: Regenerate skills/1-hourly/relay-automation/relay-pkg.tar.gz via make-pkg.sh in the same turn
- **evidence**: test/relay-pkg-freshness.sh
- **confidence**: high — enforced by relay-pkg-freshness.sh
- **area**: relay
- **source**: https://github.com/HiQS-Labs/XYZ-forge/issues/261
- **date**: 2026-10-05

## Entry 6: Sixth lesson
- **cue**: Counting live manifest items across release transitions
- **lesson**: Use COUNT(DISTINCT issue_ref_id) in _live_manifest_count so shipped+redialed issues count once
- **evidence**: TESTS-RESULTS/2026-10-25+GH-1222/manual-check.md
- **confidence**: high — red/green SQLite reproducer
- **area**: releases
- **source**: https://github.com/HiQS-Labs/XYZ-forge/issues/1222
- **date**: 2026-10-06

## Entry 7: Seventh lesson (newest)
- **cue**: Checking worktree cleanliness after a builder command in improve-loop.sh
- **lesson**: Snapshot worktree porcelain + untracked content manifest before and after the builder command
- **evidence**: TESTS-RESULTS/2026-10-25+GH-1221/manual-check.md
- **confidence**: high — verified against no-op and mutating builders
- **area**: marathon
- **source**: https://github.com/HiQS-Labs/XYZ-forge/issues/1221
- **date**: 2026-10-07
- **superseded-by**: none
"""
    with open(os.path.join(tmp, "LESSONS-LEARNED.md"), "w") as f:
        f.write(lessons_md)

    py_present = RelayTurnLib(tmp, root, relay_file, "art.md").turn_prompt("agy", "T-1218", "codex")
    bash_present = subprocess.check_output(
        ["bash", "-c", 'XYZ_PYTHON=0; source "$1/relay-automation/relay-turn-lib.sh"; rtl_init "$2" "$3" "art.md"; rtl_turn_prompt agy "$3" T-1218 "art.md" codex', "_", root, tmp, relay_file],
        text=True
    )
    sc_present = subprocess.check_output(
        ["bash", "-c", 'source "$1/relay-automation/relay-turn-lib.sh"; ROOT="$2"; f="$3"; me="agy"; t="T-1218"; ALLOW_PATHS="art.md"; RELAY_PEER="codex"; rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"; prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"; printf "%s" "$prompt"', "_", root, tmp, relay_file],
        text=True
    )

    assert py_present == bash_present == sc_present
    block = py_present[py_present.index("[lessons learned"):]
    print("=== CAPTURED LESSONS BLOCK (7 entries, 1 superseded) ===")
    print(block)

    # 3. Non-monotonic / out-of-order dates control (Entry 1 dated 2026-12-31, Entries 2..6 dated 2026-10-02..2026-10-06)
    ooo_md = """# Lessons Learned

## Entry 1
- **cue**: Cue 1 (future-dated / corrected date)
- **date**: 2026-12-31

## Entry 2
- **cue**: Cue 2 (oldest date)
- **date**: 2026-10-02

## Entry 3
- **cue**: Cue 3
- **date**: 2026-10-03

## Entry 4
- **cue**: Cue 4
- **date**: 2026-10-04

## Entry 5
- **cue**: Cue 5
- **date**: 2026-10-05

## Entry 6
- **cue**: Cue 6
- **date**: 2026-10-06
"""
    with open(os.path.join(tmp, "LESSONS-LEARNED.md"), "w") as f:
        f.write(ooo_md)

    py_ooo = RelayTurnLib(tmp, root, relay_file, "art.md").turn_prompt("agy", "T-1218", "codex")
    bash_ooo = subprocess.check_output(
        ["bash", "-c", 'XYZ_PYTHON=0; source "$1/relay-automation/relay-turn-lib.sh"; rtl_init "$2" "$3" "art.md"; rtl_turn_prompt agy "$3" T-1218 "art.md" codex', "_", root, tmp, relay_file],
        text=True
    )
    sc_ooo = subprocess.check_output(
        ["bash", "-c", 'source "$1/relay-automation/relay-turn-lib.sh"; ROOT="$2"; f="$3"; me="agy"; t="T-1218"; ALLOW_PATHS="art.md"; RELAY_PEER="codex"; rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"; prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"; printf "%s" "$prompt"', "_", root, tmp, relay_file],
        text=True
    )
    assert py_ooo == bash_ooo == sc_ooo
    ooo_block = py_ooo[py_ooo.index("[lessons learned"):]
    print("=== CAPTURED LESSONS BLOCK (6 entries, out-of-order dates) ===")
    print(ooo_block)

    print("=== EQUALITY CHECKS ===")
    print(json.dumps({
        "absent_silent": "[lessons learned" not in py_absent,
        "absent_identical_py_bash_smallcode": (py_absent == bash_absent == sc_absent),
        "present_identical_py_bash_smallcode": (py_present == bash_present == sc_present),
        "superseded_entry_4_skipped": ("Entry 4" not in py_present),
        "oldest_entry_1_omitted": ("Entry 1" not in py_present),
        "bodies_excluded": ("MUST NOT appear" not in py_present),
        "pointer_count": sum(1 for line in block.splitlines() if line.startswith("- Entry ")),
        "omitted_line": block.splitlines()[-1],
        "ooo_identical_py_bash_smallcode": (py_ooo == bash_ooo == sc_ooo),
        "ooo_oldest_entry_2_omitted": ("Entry 2" not in ooo_block),
        "ooo_selected_entries": [line.split(" — ")[0] for line in ooo_block.splitlines() if line.startswith("- Entry ")],
    }, indent=2))
PYEOF
````

### Observed Output

```text
=== CAPTURED LESSONS BLOCK (7 entries, 1 superseded) ===
[lessons learned (LESSONS-LEARNED.md) — informational, warn-only; inspect LESSONS-LEARNED.md when a cue matches your task]
- Entry 2: Second lesson — cue: Tightening a verification gate or post-merge check
- Entry 3: Third lesson — cue: Running probes during a reviewer relay turn
- Entry 5: Fifth lesson — cue: Editing relay-turn-lib.sh or any packaged relay script
- Entry 6: Sixth lesson — cue: Counting live manifest items across release transitions
- Entry 7: Seventh lesson (newest) — cue: Checking worktree cleanliness after a builder command in improve-loop.sh
+1 earlier lesson(s) omitted — see LESSONS-LEARNED.md for full history.
=== CAPTURED LESSONS BLOCK (6 entries, out-of-order dates) ===
[lessons learned (LESSONS-LEARNED.md) — informational, warn-only; inspect LESSONS-LEARNED.md when a cue matches your task]
- Entry 1 — cue: Cue 1 (future-dated / corrected date)
- Entry 3 — cue: Cue 3
- Entry 4 — cue: Cue 4
- Entry 5 — cue: Cue 5
- Entry 6 — cue: Cue 6
+1 earlier lesson(s) omitted — see LESSONS-LEARNED.md for full history.
=== EQUALITY CHECKS ===
{
  "absent_silent": true,
  "absent_identical_py_bash_smallcode": true,
  "present_identical_py_bash_smallcode": true,
  "superseded_entry_4_skipped": true,
  "oldest_entry_1_omitted": true,
  "bodies_excluded": true,
  "pointer_count": 5,
  "omitted_line": "+1 earlier lesson(s) omitted \u2014 see LESSONS-LEARNED.md for full history.",
  "ooo_identical_py_bash_smallcode": true,
  "ooo_oldest_entry_2_omitted": true,
  "ooo_selected_entries": [
    "- Entry 1",
    "- Entry 3",
    "- Entry 4",
    "- Entry 5",
    "- Entry 6"
  ]
}
```

## 2. Worked Example: Evidence-Gated Writer Rule (Refusal vs Acceptance)

### Case A — Refused Candidate (`NO_ENTRY`)

Candidate from a task doc's `## Lessons Learned` section:
- Changed components (`Edit verdicts` table):

| Component | Verdict | Notes |
|---|---|---|
| `utils/py/consult.py` | `confounded` | Prompt wording and timeout changed together; single unlogged run |
| `skills/1-hourly/consult/SKILL.md` | `no observed effect` | Documentation update only |

- Candidate fields:
  - `- **cue**:` Running cross-model consults with slow responses
  - `- **lesson**:` Lower the consult timeout and simplify the prompt header
  - `- **evidence**:` *(empty — PR merge only, no committed receipt)*

**Writer adjudication:** Refused under **Admission** (`evidence` is empty; merge/adoption alone is not evidence) and **Edit verdicts** (the only behavioral row is `confounded` because two variables changed together on a single run). Output recorded in handoff: `NO_ENTRY`.

### Case B — Accepted Candidate

Candidate from GH-1222's task doc / verification receipt:
- Changed components (`Edit verdicts` table):

| Component | Verdict | Notes |
|---|---|---|
| `utils/py/releases_app.py` (`_live_manifest_count`, migration-004 backfill) | `helped` | Isolated SQL change from `COUNT(*)` to `COUNT(DISTINCT issue_ref_id)` eliminated double-counting of shipped+redialed issues in red/green SQLite probe |

- Accepted entry drafted for `LESSONS-LEARNED.md`:

```markdown
## Deduplicate manifest issue counts across state transitions
- **cue**: Counting active or baseline manifest items in `releases_app.py` when an issue can transition through `dialed_in`, `shipped`, and redialed states within one release.
- **lesson**: Query `COUNT(DISTINCT issue_ref_id)` rather than `COUNT(*)` in `utils/py/releases_app.py` (`_live_manifest_count` and migration backfills) so redialed issues are counted once per release.
- **evidence**: TESTS-RESULTS/2026-10-25+GH-1222/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1222/provenance.jsonl, https://github.com/HiQS-Labs/XYZ-forge/issues/1222
- **confidence**: high — isolated single-query change verified with a red (`COUNT(*)` = 2) and green (`COUNT(DISTINCT issue_ref_id)` = 1) SQLite reproduction.
- **area**: releases
- **source**: https://github.com/HiQS-Labs/XYZ-forge/issues/1222
- **date**: 2026-10-25
```

**Writer adjudication:** Accepted — `cue`, `lesson`, and `evidence` are non-empty; the edit verdict row is `helped` (single isolated component with red/green controls); all evidence links are repo-relative `TESTS-RESULTS/` paths and public GitHub issue URLs.

## 3. Focused Regression Suites

```text
$ bash test/relay-pkg-freshness.sh
  relay-pkg-freshness: 3 pass, 0 fail

$ bash test/gh397-reviewer-turn-role.sh
  (11 pass, 0 fail)

$ bash test/gh681-reviewer-probe-rules.sh
  gh681-reviewer-probe-rules: all cases passed (22 pass, 0 fail)

$ bash test/gh91-relay-scratch.sh
  gh91-relay-scratch: 22 pass, 0 fail

$ bash test/gh304-vendored-relay-path.sh
  gh304-vendored-relay-path: 11 pass, 0 fail

$ bash test/gh609-sdlc-agent-gaps.sh
  gh609-sdlc-agent-gaps: 33 pass, 0 fail

$ bash test/gh615-start-task-reinforce.sh
  gh615-start-task-reinforce: 8 pass, 0 fail

$ bash test/gh616-start-task-commensurate-envelope.sh
  gh616-start-task-commensurate-envelope: 7 pass, 0 fail

$ bash test/gh308-frozen-twin-guard.sh --check --base HEAD
  gh308 guard: no frozen Bash twin changed
  gh308 guard: no new Bash under utils/ or relay-automation/
```


## PR #1223 review follow-up (CodeRabbit, 2026-10-25)

Finding 4370486844 (`rtl_turn_prompt` fence tracking) and 4370486847 (this receipt's outer fence, now four backticks).

Probe: a fixture `LESSONS-LEARNED.md` with one real entry, plus a ```` ```` ```` fenced example containing a ```` ``` ```` line, a `## Fake copied example` heading and a `- **cue**: FAKE-CUE` line.

| | Red (`cb1e2d50`) | Green (fix) |
|---|---|---|
| Pointers emitted | `Real lesson — cue: REAL-CUE` **and** `Fake copied example — cue: FAKE-CUE` | `Real lesson — cue: REAL-CUE` only |

Fix: a fence closes only on a bare backtick run at least as long as its opener. `relay-pkg.tar.gz` was regenerated: `relay-pkg-freshness` 3/0; `gh397`, `gh681` and `relay-self-sufficiency` green.
