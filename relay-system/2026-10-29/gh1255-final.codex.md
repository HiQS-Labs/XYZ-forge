# RELAY · GH-1255 Rebalance GH-368 final implementation and tracking QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-29.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1255-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: .relay-artifacts/gh1255-final-packet.md; actual upstream code/tests/docs and TESTS-RESULTS/2026-10-29+GH-368; packet also includes Forge tracking/parity diff
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-29
- Definition of Done: Review the approved requirements, complete changed files and verification receipts, including red controls and one-line stale-window fixture correction. Verify durable replay after partial writer failure, response-item/child exclusion, diagnostic-only canary and existing-suite-only scope. Review Forge tracking scope in the packet as part of the same delivery. No unrequested enterprise threat model or infrastructure. Grade on the local capture contract and commensurate complexity. No live deployment/latency claim; pending merge and standalone publication are explicit. Static gate will rerun on final push. Writes limited to this relay thread; no Git commands, source edits or test execution.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL

Basis: Implementation and retained clone receipts support the approved local capture contract. One recovery-command correction is required before approval; no production redesign or additional suite is requested.

swept file: yes

Read the entire packet, full tailer, both changed test files, rollout fixture, INSTALL, version files, upstream project document and retained verification receipts; reviewed Forge tracking/parity and release changes. No additional pre-existing defect found in the capture/replay paths examined. The documented age-only lock limitation remains an accepted constraint with exclusive replay instructions. No Git commands, suites, executable fixtures, live capture or deployment were run in this turn.

- [Should] R1 — Repair the recovery command at `utils/clio-capture/INSTALL.md:739` (also packet line 426). It currently reads `` `CLIO_TAIL_BACKFILL=1 `/.claude/hooks/clio-codex-tail.sh` ``: the inline code closes before the executable, and the executable path lacks the home directory. This is the central operator step for recovering missed history, not merely cosmetic formatting. Replace the entire inline span with `CLIO_TAIL_BACKFILL=1 "$HOME/.claude/hooks/clio-codex-tail.sh"`, enclosed in one balanced Markdown code span. Preserve the surrounding quiesce/restore procedure; refresh the packet from corrected upstream docs.
  Observed input: literal source line 739 reproduced by the read-only probe below; no installed command was executed.
  Affected scope: this one documented manual replay invocation, with no runtime behavior change.
  Falsifier: the corrected source and refreshed packet each render one code span containing the assignment and the quoted home-relative executable path; a source line already containing those bytes would make this finding unnecessary.
- [Pass] Parser/provenance and cursor contracts: `utils/clio-capture/clio-codex-tail.sh:121-150` establishes first-file provenance and newline consumption; `:172-198` excludes children/response items and accepts only legacy or modern UserMessage text with timestamp eligibility; `:269-274` checkpoints replay before extraction/delivery; `:325-341` retains that checkpoint after writer rejection. Existing suite assertions at `test/clio-codex-tail.sh:311-334` require one row after the second-write failure, offset/eligibility zero, two rows on ordinary retry, stable record IDs on repeated replay and unchanged source/cutoff. Retain these paths and assertions.
- [Pass] Diagnostic scope stays bounded: `utils/clio-capture/clio-codex-tail.sh:345-361` caps the streak at three, warns only on threshold crossing, resets for idle/acceptance/deferred writer/backfill and explicitly says activity alone does not prove lost prompts. `test/clio-codex-tail.sh:343-368` covers threshold and resets; `red-disabled-canary.txt` contains "AssertionError: canary must warn once at three active ticks". No infrastructure expansion is warranted.
- [Pass] Retained evidence distinguishes failures from corrected passes: `red-base-modern.txt` reports "expected the two user prompts delivered" versus `delivered=1`; `red-lost-replay-checkpoint.txt` reports "replay intent lost on writer failure"; `clio-codex-tail-final.txt` reports the modern/replay/SQLite/canary pass. `base-store-control.txt` retains `AssertionError: 4 != 5`, and `clio-store-final.txt` retains "Ran 17 tests" / "OK". The one-line `test/clio-store.py:978` timestamp change preserves the five-row checks at `:1027` and `:1031`. Eleven hashed logs match their provenance records (probe below). These are reviewed producer clone receipts, not an independent suite rerun; retain them and let the harness rerun its gate.
- [Pass] Forge remains tracking/evidence scope: packet lines 725-727 pin parity to the baseline upstream/standalone/Forge revisions; its ending "Limits" explicitly leaves merge, publication and live 120-second acceptance outstanding. The tracking plan says "Keep Forge #1255 open until actual acceptance is met." Treat parity as baseline publication evidence, not candidate deployment proof; retain those boundaries.

Read-only probe command (exit 0; no artifact execution):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PY'
import hashlib, json
from pathlib import Path
p = Path('TESTS-RESULTS/2026-10-29+GH-368')
rows = [json.loads(s) for s in (p/'provenance.jsonl').read_text().splitlines()]
checked = [r for r in rows if 'log_sha256' in r]
for r in checked:
    assert hashlib.sha256((p/r['log']).read_bytes()).hexdigest() == r['log_sha256'], r['log']
print(f'{len(checked)} retained log SHA256 values match provenance')
for n, line in enumerate(Path('utils/clio-capture/INSTALL.md').read_text().splitlines(), 1):
    if line.startswith('`CLIO_TAIL_BACKFILL=1 '):
        print(f'INSTALL.md:{n}: {line}')
PY
```

Decisive output:

```text
11 retained log SHA256 values match provenance
INSTALL.md:739: `CLIO_TAIL_BACKFILL=1 `/.claude/hooks/clio-codex-tail.sh`. Keep other invocations stopped
```

Handing off to Producer (codex-producer) — correct R1, refresh the packet and open round 2; go to the Producer window and say 'take your turn'.

### Producer · Round 1 dispositions

R1 — Implemented: replace the complete malformed inline invocation with one balanced code span containing the backfill assignment and quoted "$HOME/.claude/hooks/clio-codex-tail.sh". Preserve quiescence, state backup and identical-schedule restoration. The seeded packet is regenerated from corrected docs.
All Pass findings acknowledged; retained receipts stay unchanged. No capture code or test behavior changed. Re-review the precise documentation correction and unchanged contracts, then approve if sufficient. Handing off to Reviewer for round 2.

### Reviewer · Round 2

VERDICT: PASS

Basis: Ship the reviewed implementation and tracking packet. R1 is resolved in both the canonical installation instructions and refreshed packet. The local capture contract and retained clone evidence support approval; deployment and live acceptance remain separate.

swept file: yes

Read the entire packet, complete tailer, both changed test files, rollout fixture, INSTALL and upstream project document, including pre-existing sections; rechecked verification provenance and decisive retained logs. No additional material pre-existing defect found in the reviewed capture/replay paths. No Git commands, suites, executable fixtures or installed capture were run this turn.

- [Pass] R1 closed: `utils/clio-capture/INSTALL.md:739` and packet `:426` now contain the single balanced span `CLIO_TAIL_BACKFILL=1 "$HOME/.claude/hooks/clio-codex-tail.sh"`. The surrounding procedure at INSTALL `:733-747` retains quiescence, state backup and restoration of the identical previously loaded job on success or failure. Read-only probe below exits 0. Retain this correction.
- [Pass] Capture and retry contracts remain sound on source inspection: `utils/clio-capture/clio-codex-tail.sh:121-150` keeps first-file child provenance and complete-line consumption; `:172-198` accepts submitted modern/legacy text only; `:269-274` checkpoints replay before delivery; `:325-341` leaves that checkpoint pending after a rejected write. `test/clio-codex-tail.sh:311-334` requires nonempty SQLite capture, ordinary retry without the replay flag, stable IDs and unchanged source/cutoff. No behavior change requested.
- [Pass] Diagnostic and evidence scope stays bounded: tailer `:345-361` implements the capped threshold/reset warning and says activity alone does not prove lost prompts; existing suite `:343-368` covers threshold/reset. Retained `red-base-modern.txt` says "expected the two user prompts delivered" with `delivered=1`; `red-lost-replay-checkpoint.txt` says "replay intent lost on writer failure"; `red-disabled-canary.txt` says "canary must warn once at three active ticks". `clio-codex-tail-final.txt` records the corrected pass; `clio-store-final.txt` records "Ran 17 tests" and "OK". These are producer clone receipts, not a reviewer rerun. All 11 retained hashed logs match provenance in the read-only probe below.
- [Pass] The stale-window correction remains one fixture line at `test/clio-store.py:978`, using `store.utc()` while preserving five-row assertions at `:1027` and `:1031`; `base-store-control.txt` retains "AssertionError: 4 != 5". No production store change or new suite is needed.
- [Pass] Forge remains tracking/parity evidence: packet `:725-727` pins baseline revisions, and its "Limits" / "Final round 2 addendum" distinguish pending publication/live acceptance from implementation evidence and explicitly disclose existing Rebalance PDDA observe findings. The approved plan says "Keep Forge #1255 open until actual acceptance is met." Retain these boundaries and the planned final-push gate rerun; this relay approval is not deployment or merge authorization.

Read-only probe command (exit 0; reads text/hashes only):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PY'
import hashlib, json
from pathlib import Path
needle = '`CLIO_TAIL_BACKFILL=1 "$HOME/.claude/hooks/clio-codex-tail.sh"`'
for name in ("utils/clio-capture/INSTALL.md", ".relay-artifacts/gh1255-final-packet.md"):
    lines = Path(name).read_text().splitlines()
    hits = [(n, line) for n, line in enumerate(lines, 1) if needle in line]
    assert len(hits) == 1, (name, hits)
    for n, line in hits:
        assert line.count("`") == 2
        print(f"{name}:{n}: {line}")
p = Path("TESTS-RESULTS/2026-10-29+GH-368")
rows = [json.loads(line) for line in (p/"provenance.jsonl").read_text().splitlines()]
checked = [r for r in rows if "log_sha256" in r]
for r in checked:
    assert hashlib.sha256((p/r["log"]).read_bytes()).hexdigest() == r["log_sha256"], r["log"]
print(f"{len(checked)} retained log SHA256 values match provenance")
PY
```

Decisive output:

```text
utils/clio-capture/INSTALL.md:739: `CLIO_TAIL_BACKFILL=1 "$HOME/.claude/hooks/clio-codex-tail.sh"`. Keep other invocations stopped
.relay-artifacts/gh1255-final-packet.md:426: +`CLIO_TAIL_BACKFILL=1 "$HOME/.claude/hooks/clio-codex-tail.sh"`. Keep other invocations stopped
11 retained log SHA256 values match provenance
```

Relay closed (Approved), no further turn needed. Harness owns the file-scoped commit and subsequent gate.


### Attestation · relay-drive — 2026-10-30T01:38:45Z
task: RELAY-gh1255-final
reviewer: codex
status: Approved
reviewed-head: f02b3ca1ea228f210e8917c11d3ef9c67efb32ef
added-range: 11804+4587
added-sha256: 082f144ac59c4ab8889f12cb71ad82ec051a506b5d1a6c5c0c2015fb4fdc64fb
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
