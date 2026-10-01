# RELAY · GH-909 final QA: stable completion lock
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-01.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh909-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-909-COMPLETION-LOCK-LOSS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-909-COMPLETION-LOCK-LOSS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-01
- Definition of Done: Review the complete committed diff versus origin/development for GH-909, production writer plus all three changed existing suites, governed plan, red/focused/ATE receipts and ratings. Confirm stable flock spans JSON read/replace, never unlinks, preserves schema and wait/progress/75 contracts. No new tests/registry/runners. macOS/Linux local filesystem only, cooperating upgraded writers, verified quiescent cutover required; no enterprise scope. Focused evidence at 266a954a; final full gate is deliberately pending after approval, not a reason to expand scope. Review full files; no suites in worktree. Findings must cite observed input and falsifier.  _<fill in the acceptance criteria the Reviewer grades against>_  [Unverified — no citation]

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: The bounded GH-909 repair satisfies the implementation/focused-evidence acceptance criteria. Approval is final QA approval, with the final full gate and verified quiescent deployment still outstanding as planned.
swept file: yes

- [Pass] **One stable lock spans the complete transaction.** `utils/telemetry/append-xyz-completion.sh:54–82` opens the same sidecar without truncation, acquires nonblocking exclusive flock, and writes the acquisition token only under ownership. The descriptor remains open through JSON read (`84–93`), schema-preserving prepend (`95–102`) and atomic same-directory replacement (`104–116`). No release path unlinks the sidecar; the only unlink targets the temporary JSON file on error. Other acquisition errors escape before JSON mutation. Fix: retain this lifecycle; no further runtime change requested.
- [Pass] **Wait/progress/75 and existing fixtures remain proportionate.** Writer `45–46,60–78` retains 30s/default 4x cap, uses monotonic time, rearms on token changes, and keeps the absolute cap independent of progress. `test/gh123-lock-progress-bound.sh` sections A/B use actual flock ownership and an inherited descriptor to avoid early unlocked acquisition. Its committed log reports “stuck holder still exits 75 ... after 2s” and moving progress acquired after 6s. `test/gh358-lock-instrumentation.sh` control 2 uses a real holder; its log distinguishes both clobbered-success and starvation failures. `test/xyz-completion.sh:176–185` checks the retained sidecar is unlocked; its log ends “44 pass, 0 fail.” Fix: retain the three existing suite adaptations; no new suite or gate requested.
- [Pass] **Causal red/green and focused receipts support the stated claim.** `red-handoff/result.json` records three zero exits, removed successor lock and B/A with W lost. `focused/manual-result.json` records W/B/A, preserved successor inode, blocked waiter, crash release and legacy refusal rc=1. Full reads of both scheduling scripts and instrumented writers found the green copy differs only by scheduling barriers/imports. `focused/provenance.jsonl:1` attributes the three suite successes and 77 ATE variations to `266a954a8c82aea5a8267e3ed4e66391f14d9f79`; identity snapshots match. These are retained observations, not fresh executable replays. Fix: preserve the receipts and run the planned final gate.
- [Pass] **Committed scope and tested bytes match.** A read-only Python object-store query (no git command) compared stored origin/development `57bd97af4a0e8d456927e20b49d64b232d95f36d` with review HEAD `c02f4ae62debd1f34f2b416ab9ce560efdbc3d34`. Exit 0; decisive output: `WORKTREE_SOURCE_MATCH True`, `RECEIPT_HASH_MATCH True`, `ATE_ROWS 77`. Changed runtime scope is exactly the writer plus the three existing suites; remaining changes are GH-909 docs, ledger and relay/verification receipts. No new suite, registry entry or runner. A second read-only loose-object comparison against the receipt SHA exited 0: `all four source files equal tested 266a954a`. Fix: retain that bounded scope.
- [Pass] **Governance and deployment envelope are honest.** Artifact `20,37,40,43–57` preserves the pending final gate, requires stopping/retiring old running and waiting writers before rollout or rollback, refuses legacy directories without claiming live mixed-version safety, and limits guarantees to cooperating upgraded local macOS/Linux writers. Ratings `85/85/50/65` at line 50 distinguish telemetry loss from unproven agent-work loss and recurrence. Read-only SQLite inspection found GH-909 in progress with the exact working-doc pointer; the initial query used an incorrect column name (exit 1), then schema inspection and corrected query exited 0. PRS numeric rating fields are unset; the stated ratings are in the governed plan. Fix: retain the explicit envelope and deployment prerequisite.
- [Nit] `test/xyz-completion.sh:8` still advertises “no leftover temp file / lock dir,” while section 5 now correctly retains an unlocked file. Update that summary comment to describe retained unlocked sidecar semantics when convenient; no behavior change or extra verification machinery needed.

Receipt integrity/ATE/source-copy probe (read-only; exit **0**):

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PYPROBE'
import pathlib,json,hashlib,ast
p=pathlib.Path('TESTS-RESULTS/2026-10-01+GH-909/focused')
h=json.loads((p/'sha256.json').read_text())
assert h and all(hashlib.sha256((p/n).read_bytes()).hexdigest()==v for n,v in h.items())
assert (p/'identity-before.json').read_bytes()==(p/'identity-after.json').read_bytes()
a=[json.loads(l) for l in (p/'ate/error_log.jsonl').read_text().splitlines()]
assert len(a)==77
n=0
for x in a:
    y=json.loads(x['stdout'])
    assert x['exit_code']==0 and not x['timed_out'] and not x['stderr']
    assert y['zero_exits'] and y['records']==y['distinct']==y['writers']
    n+=y['records']
assert n==2848
s=pathlib.Path('utils/telemetry/append-xyz-completion.sh').read_text()
for x in ast.parse((p/'manual.py').read_text()).body:
    if isinstance(x,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='s' for t in x.targets) and isinstance(x.value,ast.Call) and isinstance(x.value.func,ast.Attribute) and x.value.func.attr=='replace':
        old,new=map(ast.literal_eval,x.value.args)
        assert s.count(old)==1
        s=s.replace(old,new)
assert s==(p/'green-writer.sh').read_text()
print('hashes intact; identity identical; 77 zero-exit rows; 2848 records; replay copy equals production plus scheduling barriers/imports')
PYPROBE
```

Decisive output: `hashes intact; identity identical; 77 zero-exit rows; 2848 records; replay copy equals production plus scheduling barriers/imports`.

Whole artifact, production writer, all three changed suites and red/green probe sources swept; no additional blocking pre-existing defects found within this bounded repair. The existing suites retain unguarded mktemp/cleanup patterns covered by the repository's disposable-clone execution rule; this review did not execute them. Graph inventory had no matching worktree project; canonical XYZ-forge generation `2026-09-01T15:54:30Z` belongs to another checkout. Coverage checks were therefore only leads; current full source reads supplied review evidence. No suites, pytest, executable fixtures or git commands ran here. Total-cap enforcement is source-reviewed, not independently stressed in this turn. Linux portability and live rollout quiescence are not newly attested.

Relay closed (Approved), no further review turn needed. Producer (claude-a) should proceed to the planned disposable-clone full gate, exact-head evidence and verified quiescent cutover before deployment.  [Unverified — no citation]

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
