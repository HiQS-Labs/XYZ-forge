# RELAY · GH-1255 pre-landing documentation and replay-contract disposition
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
6. **Commit only the relay file** (`relay(gh1255-prelanding): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1255-prelanding-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file temp/gh1255-prelanding-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-29
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

- Definition of Done: Review current full documentation and the scoped correction delta. Runtime unchanged from prior Approved gate. Assess per-file replay limitation disposition, schedule/recovery ordering, upstream canonical receipt links, current QA/roadmap status, date-only changed heading. No implementation, suites or git commands; write only this relay with graded findings and a PASS/FAIL verdict.

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
Basis: The replay limitation, recovery ordering and QA corrections are appropriate, but the roadmap status edit also erases the existing four ratings. Restore that unrelated data loss before approval. Round cap reached; return to Producer for the bounded correction.
swept file: yes

Read the entire 1,846-line seeded packet: complete INSTALL, tailer, both project documents, prior publication review/attestation, and both scoped deltas. No additional material pre-existing defect found within the reviewed documentation/capture contract. All packet citations below refer to `.relay-artifacts/gh1255-prelanding-packet.md`; unchanged runtime was inspected, not executed.

- [Should] Preserve GH-1255's existing ratings while updating status. Packet :1829 has `rating_pri/rating_sev/rating_appeal/rating_effort = 85/85/50/65`; :1830 replaces all four with `NULL`, although the current plan still records `rated 85/85/50/65` at :1423. This is an unintended loss of queryable prioritization data, not a QA-status correction. Use the existing RELEASES CLI to retain the new status while restoring `(rated 85/85/50/65)` and the canonical document/issue links in `raw_text`; regenerate through the CLI, never hand-edit the dump. The structured `doc_path` and `issue_url` remain present, so this is not a claim that the underlying pointers were deleted.
  Observed input: The removed and added GH-1255 INSERT rows at packet :1829-1830; the replacement raw_text omits both the rating token and Markdown links.
  Affected scope: Only GH-1255's status-update row and its CLI-generated ledger representation; no runtime or general ledger behavior change requested.
  Falsifier: A revised exported GH-1255 row retaining the new QA/pending-acceptance wording, existing document/issue pointers, and numeric ratings `85,85,50,65` would resolve this finding. NULL ratings while the plan retains those values do not.
- [Pass] The per-file limitation is explicit and matches the implementation: packet :715 says "Only files reached by that invocation have durable replay intent"; :780-783 requires repeating the flag for unvisited files after interruption. The checkpoint is inside the file loop at :1223-1227, before delivery. Keep this bounded disposition; no global replay journal is required by the approved per-file contract.
- [Pass] Recovery follows the scheduling block at packet :740-765 and requires exclusive execution at :769-776. The restoration instruction at :778-783 preserves the previously loaded/unloaded state on success and failure. Per-session SQLite checks and a new submission within 120 seconds remain explicit at :785-791. Retain these instructions; no schedule or lock implementation change requested.
- [Pass] Canonical receipt ownership and pending deployment are stated honestly: packet :1374 and :1378 replace local upstream transcript references with Forge links; :1390 names the superseding pinned publication receipt. The embedded publication review says `STATUS: Approved` at :1508 and includes its driver attestation at :1637-1643. Current plan text at :1474 and :1482 separates Approved QA from pending deployment. These are packet-level consistency findings, not fresh remote-link or attestation validation.
- [Pass] The CHANGELOG delta at packet :1757-1760 replaces the descriptive heading with `## 2026-10-29` and retains its description as prose, matching `PROJECT/PDDA.md:1005`. Preserve this correction.
- [Unverified — needs clone run] No suites, executable fixtures, Git commands, deployment or live database probes ran in this turn. Runtime equivalence to the prior tested revision is a producer assertion supported by the scoped documentation-only diff, not a fresh byte comparison. The harness owns the commit and post-turn gate; remote PR state, remote receipt availability and scheduled target-device acceptance are not established by this review.

Read-only probe for the rating finding (exit 0; parses packet text only, executes no artifact code):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PY'
import csv, re
from pathlib import Path
p=Path('.relay-artifacts/gh1255-prelanding-packet.md')
s=p.read_text()
rows={}
for n,line in enumerate(s.splitlines(),1):
    if line[:1] in ('-','+') and line[1:].startswith('INSERT INTO roadmap_items(') and "'1255'" in line:
        m=re.fullmatch(r"[+-]INSERT INTO roadmap_items\((.*?)\) VALUES\((.*)\);",line)
        assert m
        row=dict(zip(m[1].split(', '),next(csv.reader([m[2]],delimiter=',',quotechar="'",skipinitialspace=True))))
        rows[line[0]]=row
        print(f'packet:{n} {line[0]} ratings=' + '/'.join(row[k] for k in ('rating_pri','rating_sev','rating_appeal','rating_effort')))
        print('doc_path='+row['doc_path'])
        print('raw_text='+row['raw_text'])
assert set(rows)=={'-','+'}
assert [rows['-'][k] for k in ('rating_pri','rating_sev','rating_appeal','rating_effort')]==['85','85','50','65']
assert all(rows['+'][k]=='NULL' for k in ('rating_pri','rating_sev','rating_appeal','rating_effort'))
print('Observed regression: all four previously populated ratings become NULL.')
print('Packet lines='+str(len(s.splitlines())))
PY
```

Decisive output:

```text
packet:1829 - ratings=85/85/50/65
packet:1830 + ratings=NULL/NULL/NULL/NULL
Observed regression: all four previously populated ratings become NULL.
Packet lines=1846
```

Handing off to Producer (codex-producer) — restore the existing ratings through the RELEASES CLI and submit the corrected packet for review. Go to the Producer window and say 'take your turn'.

### Producer · Round 2

Implemented the rating correction using the existing roadmap update verb with `(rated 85/85/50/65)` and canonical plan/issue links. Read SQLite and asserted numeric tuple `(85,85,50,65)`. Existing original rating-loss control was witnessed by the reviewer; candidate tuple now matches base. Staged both generated DB and SQL dump. Other review findings remain dispositioned as accepted. Please review the updated packet and approve if resolved.

### Reviewer · Round 2

VERDICT: PASS
Basis: Approve the scoped documentation and replay-contract disposition. The sole open Round-1 finding is resolved: the corrected roadmap row preserves the existing ratings and links while updating QA and pending-acceptance status. This is packet review approval; landing, deployment and scheduled target acceptance remain separate.
swept file: yes

Read the complete 1,848-line packet, including INSTALL, the complete tailer, both project documents, the prior publication review/attestation and both correction deltas. No additional material pre-existing defect found within the reviewed documentation/capture contract. All packet citations below refer to `.relay-artifacts/gh1255-prelanding-packet.md`. No artifact code was executed.

- [Pass] Round-1 rating finding resolved. Packet :1829-1830 preserves `85/85/50/65`, the row identity, structured plan/issue pointers, and in-progress status. The replacement raw_text includes `(rated 85/85/50/65)`, both Markdown links, `Plan and final Codex QA Approved`, and `scheduled device acceptance pending`. The text-only probe below checks the actual exported rows and rejects an in-memory NULL-rating control. Retain this correction; no further ledger edit requested. This does not independently establish the staged SQLite binary or DB/dump parity.
- [Pass] Replay disposition matches the bounded implementation. Packet :713-714 explicitly limits durable intent to reached files and requires repeating the flag for unvisited files. The per-file checkpoint at :1223-1227 occurs inside the scan loop before writer delivery; :1292-1295 retains failed chunks. Recovery at :780-783 explains both ordinary visited-file retry and explicit full-scan retry. Preserve the per-file contract; no global replay journal requested.
- [Pass] Scheduling/recovery order and acceptance remain explicit. Packet :738-765 precedes the recovery section at :767; :769-775 requires reviewed publication/deployment and exclusive replay. Lines :777-783 restore the identical previously loaded job on success or failure, preserve unloaded state and the backup, and forbid rewinding SQLite. Lines :785-791 require per-session row/identity checks and a new submission observed within 120 seconds. Retain these instructions.
- [Pass] QA and receipt ownership are consistently bounded in the current prose. Packet :1374 and :1378 link upstream readers to Forge's canonical final/plan receipts; :1390 pins the superseding publication receipt. The embedded prior review is Approved at :1508 and carries the driver block at :1637-1643. Current acceptance wording at :1474, :1482 and :1830 keeps deployment outstanding. These are internal packet-consistency findings, not fresh remote receipt or PR-state validation.
- [Pass] The CHANGELOG delta at packet :1757-1760 uses `## 2026-10-29` and retains the description as prose, matching the dated-heading contract in `PROJECT/PDDA.md:1005`. No further heading correction requested.
- [Unverified — needs clone run] No suites, executable fixtures, Git commands, live database queries or deployment ran in this turn. The scoped deltas contain documentation/ledger corrections; runtime equivalence to the previously tested revision remains a producer assertion rather than a fresh byte comparison. The harness owns the file-scoped commit and post-turn gate. DB/dump parity, remote receipt availability, final push checks and scheduled device recovery are not established here.

Read-only probe command (exit 0; parses packet text only, mutates only an in-memory control):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PY'
import csv, hashlib, re
from pathlib import Path
p = Path('.relay-artifacts/gh1255-prelanding-packet.md')
data = p.read_bytes()
assert data
rows = {}
for n, line in enumerate(data.decode().splitlines(), 1):
    if line[:1] in ('-', '+') and line[1:].startswith('INSERT INTO roadmap_items(') and "'1255'" in line:
        m = re.fullmatch(r"[+-]INSERT INTO roadmap_items\((.*?)\) VALUES\((.*)\);", line)
        assert m
        keys = m[1].split(', ')
        values = next(csv.reader([m[2]], delimiter=',', quotechar="'", skipinitialspace=True))
        assert len(keys) == len(values)
        assert line[0] not in rows
        rows[line[0]] = dict(zip(keys, values))
        print(f"packet:{n} {line[0]} ratings=" + '/'.join(rows[line[0]][k] for k in ('rating_pri', 'rating_sev', 'rating_appeal', 'rating_effort')))
assert set(rows) == {'-', '+'}
fields = ('rating_pri', 'rating_sev', 'rating_appeal', 'rating_effort')
def retained(row):
    return tuple(row[k] for k in fields) == ('85', '85', '50', '65')
assert retained(rows['-']) and retained(rows['+'])
for key in ('global_id', 'gh_number', 'doc_path', 'issue_url', 'first_seen', 'section', 'status_label'):
    assert rows['-'][key] == rows['+'][key], key
raw = rows['+']['raw_text']
for token in ('(rated 85/85/50/65)', '(' + rows['+']['doc_path'] + ')', '(' + rows['+']['issue_url'] + ')', 'Plan and final Codex QA Approved', 'scheduled device acceptance pending'):
    assert token in raw, token
control = dict(rows['+'])
control.update({key: 'NULL' for key in fields})
assert not retained(control)
print('PASS: ratings, structured pointers, Markdown links and pending-acceptance status retained')
print('CONTROL: prior NULL-rating regression rejected')
print('Packet lines=' + str(len(data.decode().splitlines())))
print('Packet SHA256=' + hashlib.sha256(data).hexdigest())
PY
```

Decisive output:

```text
packet:1829 - ratings=85/85/50/65
packet:1830 + ratings=85/85/50/65
PASS: ratings, structured pointers, Markdown links and pending-acceptance status retained
CONTROL: prior NULL-rating regression rejected
Packet lines=1848
Packet SHA256=8bd7208852de9c33de1b1a09e11a1963cb213df7a4b130d934fe27cf42dccbb4
```

Relay closed (Approved), no further turn needed. The harness owns the commit and subsequent gate.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
