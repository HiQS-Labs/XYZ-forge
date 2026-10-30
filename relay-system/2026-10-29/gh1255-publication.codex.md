# RELAY · GH-1255 final review round 3 — upstream fix and machine receipt publication
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-29.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 3

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
6. **Commit only the relay file** (`relay(gh1255-publication): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1255-publication-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file temp/gh1255-publication-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-29
- Definition of Done: Final independent gate for Forge #1255 / Rebalance #368. This is final review round 3: prior rounds found only a recovery-command typo, now fixed. The upstream target ignores relay-system so its approved turn could not publish a machine attestation. Review the complete upstream source/changed suites/verification logs and prior review dispositions in the seeded artifact; the same-repo Forge driver must attest your actual turn. No source or policy edits. No extra infrastructure, suites or unrelated cleanup. Grade against the local capture contract and commensurate complexity; live deployment remains pending. Writes limited to this relay file. Do not run suites or git.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 3

VERDICT: PASS
Basis: Approve the seeded implementation/publication packet against the local capture contract. The recovery-command correction and prior plan dispositions are present; the retained clone receipts support the scoped implementation. This approval does not attest a machine gate that has not yet completed, authorize merge/deployment, or establish live recovery.
swept file: yes

Read the entire 4,268-line packet, including the complete tailer, both changed suites, INSTALL, fixture/version diffs, tracking/parity evidence, prior turns and retained logs. No additional material pre-existing defect found in the reviewed capture/replay paths. The known age-only lock limitation remains explicitly bounded by exclusive replay instructions. All citations below refer to `.relay-artifacts/gh1255-publication-packet.md`.

- [Pass] Submitted-event provenance and retry behavior remain aligned with the plan: packet :1013 establishes first-file provenance; :1062 excludes children and non-event messages; :1068 accepts legacy text or modern UserMessage string text parts; :1087 applies timestamp eligibility. The replay checkpoint at :1159 precedes delivery, and :1228 advances only successful chunks. Existing-suite assertions at :1575 require a pending zero-offset/history checkpoint after the second-write failure, then ordinary retry, two stored rows, stable IDs and unchanged source/cutoff. Preserve these paths; no behavior change requested.
- [Pass] The warning remains diagnostic: packet :1238 caps/reset-checks the existing state comment, warns only at the third active zero-acceptance tick, and explicitly says activity alone does not prove lost prompts. Existing threshold/reset assertions are at :1595; the disabled-canary receipt at :4248 fails with "canary must warn once at three active ticks". No new infrastructure or suite is warranted.
- [Pass] Prior dispositions are satisfied: durable replay and exclusive scheduling were required at :3824 and :3829 and accepted at :3857-3858. The complete INSTALL recovery instruction at :3419 contains one balanced span, `CLIO_TAIL_BACKFILL=1 "$HOME/.claude/hooks/clio-codex-tail.sh"`; :3416 requires stopping/draining invocations and :3422 restores the identical previously loaded job on success or failure. The earlier malformed command remains only as historical review evidence. Retain the corrected current instruction.
- [Pass] Producer clone evidence is internally consistent: all 11 embedded hashed logs match their provenance records at :3698. The modern-shape red control at :4244 reports delivered=1 instead of two; :4256 reports "replay intent lost on writer failure". Corrected Codex output at :4110 records the modern/replay/SQLite/canary pass, and :4154 records "Ran 17 tests" followed by "OK". The fixture correction at :2613 uses `store.utc()` while retaining the five-row assertions; the unchanged-base failure at :4090 is "4 != 5". These are reviewed clone receipts, not a reviewer suite rerun.
- [Unverified — no citation] Forge parity stays baseline evidence: packet :727 pins the upstream/standalone/Forge revisions, and :877-887 separates source parity, pending live acceptance, existing PDDA findings and the failed cross-repo machine publication. The 15 embedded digest/mode records agree; an altered digest and empty input are rejected by the read-only comparison below. This is internal receipt consistency, not a fresh comparison against remote repositories. Keep Forge #1255 open through actual acceptance as required at :79.
- [Unverified — needs clone run] No suites, executable fixtures, Git commands, deployment or live DB probes were run in this turn. The enclosing Forge harness must commit this relay and successfully produce its actual gate/attestation; the historical approval/attestation text at :4053 does not establish successful cross-repo machine publication, which :887 explicitly disclaims. Final-push checks, merge, standalone publication, deployment, requested-session recovery and the 120-second target observation remain separate pending work.

Read-only probe command (exit 0; reads packet text and hashes only; no artifact code executed):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PYPROBE'
import hashlib, json, re
from pathlib import Path
p=Path('.relay-artifacts/gh1255-publication-packet.md')
s=p.read_text()
assert len(s.splitlines()) == 4268
section=s.split('## Complete upstream file: TESTS-RESULTS/2026-10-29+GH-368/provenance.jsonl\n\n',1)[1].split('\n## Complete upstream file:',1)[0]
receipts=[json.loads(line) for line in section.splitlines() if line.strip()]
logs=s.split('## Upstream captured logs\n\n',1)[1]
checked=[r for r in receipts if 'log_sha256' in r]
assert len(checked)==11
for r in checked:
    body=logs.split('### '+r['log']+'\n\n',1)[1].split('\n### ',1)[0].rstrip('\n')+'\n'
    assert hashlib.sha256(body.encode()).hexdigest()==r['log_sha256'],r['log']
print('11 embedded log SHA256 values match provenance')
install=s.split('## Complete upstream file: utils/clio-capture/INSTALL.md\n\n',1)[1].split('\n## Complete upstream file:',1)[0]
needle='`CLIO_TAIL_BACKFILL=1 "$HOME/.claude/hooks/clio-codex-tail.sh"`'
hits=[line for line in install.splitlines() if needle in line]
assert len(hits)==1 and hits[0].count('`')==2
print('Recovery command: one balanced span with quoted HOME executable')
parity=s.split('+++ b/TESTS-RESULTS/2026-10-29+GH-1255/parity.json\n',1)[1].split('\ndiff --git ',1)[0]
parity=json.loads('\n'.join(line[1:] for line in parity.splitlines() if line.startswith('+')))
def matches(rows):
    return bool(rows) and all(r['manifest_sha256']==r['standalone_sha256']==r['upstream_sha256'] and r['standalone_mode']==r['upstream_mode'] for r in rows)
assert len(parity['files'])==15 and matches(parity['files'])
changed=[dict(r) for r in parity['files']]; changed[0]['upstream_sha256']='0'*64
assert not matches(changed)
assert not matches([])
assert needle.replace('$HOME/','/') not in install
print('Baseline parity: 15 matching digest/mode records; altered digest and empty input rejected')
print('Packet SHA256: '+hashlib.sha256(p.read_bytes()).hexdigest())
PYPROBE
```

Decisive output:

```text
11 embedded log SHA256 values match provenance
Recovery command: one balanced span with quoted HOME executable
Baseline parity: 15 matching digest/mode records; altered digest and empty input rejected
Packet SHA256: 3a2d9ed29e4cd85234287ef9ebe962e2b465052f0f68975c85f2471c2969ef8e
```

Relay closed (Approved), no further turn needed. The harness owns the file-scoped commit and subsequent machine gate/attestation.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
