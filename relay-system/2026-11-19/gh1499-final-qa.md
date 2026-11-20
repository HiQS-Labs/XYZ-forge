# RELAY · GH-1499 Final QA: drift check tier layout
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-19.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1499-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/skill_drift_check.py`, `TESTS-RESULTS/2026-11-19+GH-1499/smoke.md`
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-19
- Definition of Done: issue #1499 — the checker walks the tier layout (or refuses a zero-skill compare);
  flat collections behave as before; no new suite (GH-831).

Simple change (plan QA skipped: the collection side now scans the same two depths the canonical side
already scans). Diff: `git diff origin/development..HEAD`. Envelope: local read-only CLI; commensurate.

Questions (cite file:line; approval = `tick done`, never release):
1. Does `scan()` now find `.xyz/skills/<tier>/<name>/SKILL.md` and still match flat `<collection>/<name>/SKILL.md`?
2. Can the depth-two glob register a nested `SKILL.md` inside a flat collection's skill folder
   (e.g. `<collection>/<skill>/<sub>/SKILL.md`) as a spurious skill, changing flat results? `smoke.md`
   records an identical flat-layout result before and after on a real Deployed Skills tree.
3. Does `smoke.md` show the pre-fix zero-compare and the post-fix comparison, i.e. would an unchanged
   candidate be caught? Do `test/gh660-skill-drift.sh` expectations still hold?

End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis; set STATUS Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1
- [Blocker] Flat collections can now hide real drift. At `utils/py/skill_drift_check.py:41-42`, globally sorting both depths lets `collection/zeta/alpha/SKILL.md` replace `collection/alpha/SKILL.md`; the comment that depth one wins is false. Ignore depth-two documents beneath a directory that already has its own SKILL.md, and ensure direct skills take precedence over tier candidates.
  Observed input: canonical `alpha/SKILL.md="fresh"`; flat collection `alpha/SKILL.md="stale"`, `zeta/SKILL.md="zeta"`, `zeta/alpha/SKILL.md="fresh"`. The nested document masks the stale real alpha.
  Affected scope: depth-two SKILL.md files below a flat skill directory, particularly names colliding with direct skills.
  Falsifier: this input must report alpha drifted; a genuine `collection/1-hourly/alpha/SKILL.md` without `collection/1-hourly/SKILL.md` must still compare alpha. Existing flat results must remain unchanged.
  Probe command (exit 0; Python bytecode disabled; inputs confined to scratch):
  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  mkdir -p "$TMPDIR"
  python3 -B - <<'PROBE'
  import importlib.util, tempfile
  from pathlib import Path
  spec=importlib.util.spec_from_file_location("drift", "utils/py/skill_drift_check.py")
  m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
  with tempfile.TemporaryDirectory(dir=".relay-scratch/tmp") as d:
      root=Path(d)
      for rel, content in {"canonical/alpha/SKILL.md":"fresh","collection/alpha/SKILL.md":"stale","collection/zeta/SKILL.md":"zeta","collection/zeta/alpha/SKILL.md":"fresh"}.items():
          p=root/rel; p.parent.mkdir(parents=True,exist_ok=True); p.write_text(content)
      r=m.scan(root/"canonical",root/"collection")
      print("flat with nested alpha:", {k:[x["skill"] for x in v] for k,v in r.items()})
      print("chosen alpha digest matches nested fresh:",r["ok"][0]["vendored_sha256"]==m._digest(root/"collection/zeta/alpha/SKILL.md"))
      (root/"collection/zeta/alpha/SKILL.md").unlink()
      print("same flat collection without nested document:", {k:[x["skill"] for x in v] for k,v in m.scan(root/"canonical",root/"collection").items()})
  PROBE
  ```
  Decisive output:
  ```text
  flat with nested alpha: {'drifted': [], 'ok': ['alpha'], 'unrecognized': ['zeta']}
  chosen alpha digest matches nested fresh: True
  same flat collection without nested document: {'drifted': ['alpha'], 'ok': [], 'unrecognized': ['zeta']}
  ```
- [Pass] Tier and direct discovery are both present in the collection glob (`utils/py/skill_drift_check.py:41`). The retained smoke records the red pre-fix zero comparison and post-fix 78 comparisons (`TESTS-RESULTS/2026-11-19+GH-1499/smoke.md:8-20`), but its identical real-tree counts do not cover nested documents.
- [Unverified — needs clone run] The existing suite is reported as seven passes at `TESTS-RESULTS/2026-11-19+GH-1499/smoke.md:22`. I read its complete expectations; no suite was executed in this linked worktree. No approval assumes a later gate.
- Whole-file sweep: read all 98 lines of the checker and all 22 lines of smoke, plus the existing gh660 suite. No additional pre-existing defect found in that bounded sweep. Graph coverage came from the main checkout generation 2026-11-18T19:39:07Z, not this worktree; smoke freshness was missing, so exact local source was used for every finding.

swept file: yes
VERDICT: FAIL
Basis: the observed flat-layout regression violates the Definition of Done and can turn a real drift into a clean comparison.
Handing off to Producer (claude-a) — fix flat-skill nesting/precedence and record focused evidence before the next review.

### Producer · Round 1

- **Blocker — Accepted, fixed.** `scan()` now builds the flat map first, admits a depth-two `SKILL.md`
  only when its parent's parent is not a skill folder, then lets the flat map overwrite (`update`).
  Fixture with your falsifier (`coll/alpha` drifted, `coll/zeta/alpha` matching): `0 ok, 1 drifted`;
  the previous candidate `ca351b11a` on the same fixture: `1 ok, 0 drifted` (red control). Real trees and
  gh660 re-run; table in `TESTS-RESULTS/2026-11-19+GH-1499/smoke.md` "Round 2"; provenance refreshed.


### Reviewer · Round 2

- [Pass] Round 1 blocker resolved: `utils/py/skill_drift_check.py:40-45` excludes depth-two documents under a direct skill and applies `vendored_by_name.update(flat)` last. The narrow probe below reports alpha drift despite a matching nested alpha, excludes a nested extra, and preserves genuine tier discovery and direct-over-tier precedence.
- [Pass] The retained red controls show both the original zero-comparison failure and the previous candidate hiding drift (`TESTS-RESULTS/2026-11-19+GH-1499/smoke.md:8-20,30-34`). The probe checked the nonempty smoke artifact's byte count and SHA256 against its provenance receipt; both match.
- [Unverified — needs clone run] Existing gh660 execution remains producer-reported (`TESTS-RESULTS/2026-11-19+GH-1499/smoke.md:35`: “7 pass, 0 fail”). Read the whole suite: the revised collection lookup preserves its flat vendors, tiered canonical lookup, mutation, extras and JSON expectations. No suite or gate was executed here; approval does not assume a later gate.
- Whole-file sweep: read all 101 checker lines and all 35 smoke lines, plus the existing gh660 suite. No additional pre-existing defect found in this bounded review. Graph coverage refers to the main checkout generation 2026-11-18T19:39:07Z, not this worktree; smoke freshness is missing. Exact local source was used throughout.

Probe command (exit 0; only scratch inputs created):
```bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 -B - <<'PROBE'
import importlib.util, tempfile, hashlib, json
from pathlib import Path
spec=importlib.util.spec_from_file_location("drift","utils/py/skill_drift_check.py")
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
with tempfile.TemporaryDirectory(dir=".relay-scratch/tmp") as d:
 r=Path(d)
 for rel,content in {"canonical/alpha/SKILL.md":"fresh","flat/alpha/SKILL.md":"stale","flat/zeta/SKILL.md":"zeta","flat/zeta/alpha/SKILL.md":"fresh","flat/zeta/extra/SKILL.md":"foreign","tier/1-hourly/alpha/SKILL.md":"fresh","mixed/alpha/SKILL.md":"stale","mixed/1-hourly/alpha/SKILL.md":"fresh"}.items():
  p=r/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(content)
 for layout in ("flat","tier","mixed"):
  result=m.scan(r/"canonical",r/layout)
  names={k:[e["skill"] for e in v] for k,v in result.items()}
  print(layout,names)
  assert names==({"drifted":[],"ok":["alpha"],"unrecognized":[]} if layout=="tier" else {"drifted":["alpha"],"ok":[],"unrecognized":["zeta"] if layout=="flat" else []})
p=Path("TESTS-RESULTS/2026-11-19+GH-1499/smoke.md")
receipt=json.loads(p.with_name("provenance.jsonl").read_text())
assert p.stat().st_size==receipt["bytes"] and hashlib.sha256(p.read_bytes()).hexdigest()==receipt["sha256"]
print("smoke receipt: bytes and SHA256 match")
PROBE
```
Decisive output:
```text
flat {'drifted': ['alpha'], 'ok': [], 'unrecognized': ['zeta']}
tier {'drifted': [], 'ok': ['alpha'], 'unrecognized': []}
mixed {'drifted': ['alpha'], 'ok': [], 'unrecognized': []}
smoke receipt: bytes and SHA256 match
```

swept file: yes
VERDICT: PASS
Basis: tier discovery meets the DoD, flat nesting no longer changes direct-skill results, and retained evidence includes red controls. No new suite requested or created; suite execution remains explicitly producer-reported.
Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-20T00:44:15Z
task: RELAY-gh1499-final-qa
reviewer: codex
status: Approved
reviewed-head: d71a41e06f5fa6f990fd46738146e48c9037f41a
added-range: 11191+3390
added-sha256: 085b269d4009709551c75052a7894b906f7ca0e886b937b6e77f7ddd235c2b1f
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
