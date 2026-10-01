# RELAY · GH-909 final QA: stable completion lock
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-01.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 4

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


### Attestation · relay-drive — 2026-10-01T19:22:53Z
task: RELAY-gh909-final
reviewer: codex
status: Approved
reviewed-head: c02f4ae62debd1f34f2b416ab9ce560efdbc3d34
added-range: 6080+6809
added-sha256: c98c60edebbc33fabab913a24fddc3b970265188436e993ef2d7501ee352c81e
### Producer · Round 2 · claude-a

- Final full gate stopped before publication on gh268 suite rc1; failed pool log retained. Present phrase caused producer Broken pipe from quiet grep under pipefail. Existing #853 owns this class.
- Added only the existing gh268 suite correction: streamed grep -Fq becomes consuming grep -F with stdout discarded, preserving every needle/conditional; file-input quiet matches unchanged. No runtime writer changes after your round1 approval.
- Focused gh268 is 35/0 at 6dca26ee. Controlled actual template repeated64x: old present rc141, fixed present rc0, fixed absent rc1. Committed receipts under gh268-blocker include input, failed pool, corrected suite log and provenance. Previous failed gate excluded, not retry-green qualification.
- Please sweep the complete new suite file, verify the narrow correction and red/green oracle, review the final source diff including unchanged completion repair, and approve only if commensurate. No new suite/registry/gate; macOS/local filesystem envelope unchanged. Full gate will run only after this fresh approval. This is review2 of the binding3-round cap.

Handing off to Reviewer (codex) — take your turn.


### Reviewer · Round 2 · codex

VERDICT: PASS
Basis: The added gh268 correction removes the observed SIGPIPE without weakening absence checks; the completion repair and its focused-tested bytes remain unchanged. Approval covers final peer QA, with the disposable-clone full gate and quiescent cutover still required.
swept file: yes

- [Pass] **Narrow, truthful existing-suite correction.** Full sweep of `test/gh268-relay-cue-and-target-checks.sh:1–281` found exactly 27 streamed `grep -Fq` substitutions to consuming `grep -F ... >/dev/null`. All needles, conditions and file-input quiet matches remain unchanged (including negative branches at `129–133,193–198,237–243`). Read-only object comparison against base `57bd97af` mechanically reconstructed the final file from only those substitutions. Concrete failure is retained in `gh268-blocker/pool-red.log:4–5`: “printf: write error: Broken pipe” followed by the false missing-cue assertion. Fix: retain this correction; no additional assertion, suite or gate machinery requested.
- [Pass] **Red/green oracle independently measured.** Using the nonempty committed `gh268-blocker/template-input.txt` (339,968 bytes), the literal pipeline probe below exited **0** and reported `old_present rc=141`, `fixed_present rc=0`, `fixed_absent rc=1`, each with empty stderr. These match `gh268-blocker/control.json`. This witnesses both the quiet-reader failure and rejection of an absent phrase. Fix: retain the consuming reader.
- [Pass] **Evidence applies to final source.** A read-only, SHA-1-validated loose/packed object-store comparison, `python3 .relay-scratch/review-r2.py`, exited **0**: `HEAD b6f03261bc08b1328ea08eb610c9668dd5d51aad`; `four completion sources equal tested 266a954a and working bytes`; `all gh268 receipts committed and equal working bytes; suite equals focused 6dca26ee`. The focused log ends “35 pass, 0 fail”; `gh268-blocker/provenance.jsonl:1` records rc0 and explicitly `no_full_qualification: true`. The first loose-only comparison exited 1 because the base object was packed; adding read-only pack decoding resolved that lookup, with reconstructed object hashes checked. Fix: run the planned full gate against the final committed state; focused results are not a full-gate qualification.
- [Pass] **Completion contract remains sound within the stated envelope.** Entire writer and all three completion suites re-read. `utils/telemetry/append-xyz-completion.sh:54–82` keeps the stable sidecar and monotonic wait/progress/75 logic; its descriptor spans JSON read/prepend and atomic replace at `84–116`, with only temporary JSON cleanup unlinked. `test/gh123-lock-progress-bound.sh:31–88` uses real held/inherited flock descriptors; `test/gh358-lock-instrumentation.sh:60–77` uses a real starvation holder; `test/xyz-completion.sh:176–185` checks retained unlocked ownership. Focused receipt integrity was rechecked: probe exit **0**, decisive output `focused hashes intact; identity intact; 77 zero-exit rows and 2848 records`. `focused/manual-result.json` retains W/B/A, preserved successor inode, blocked waiter, crash release and legacy refusal rc1. These runtime results are retained clone observations, not fresh fixture executions here. Fix: retain the bounded implementation.
- [Pass] **Scope and governance stay honest.** Object-store tree comparison against recorded origin/development base `57bd97af` shows only the writer and four existing suites as changed runtime/test sources, plus governed docs, ledger and evidence/relay receipts. No new suite, registry or runner. Artifact `37–47,50,61,65` retains cooperating upgraded local macOS/Linux writers, verified quiescence before forward/rollback cutover, ratings 85/85/50/65, failed attempts excluded, and full gate after this approval. `CHANGELOG.md:5` records the gh268 correction under #853. Fix: preserve those limits and leave umbrella issues open.
- [Nit] Round 1 comment nit remains: `test/xyz-completion.sh:8` says “no leftover temp file / lock dir,” whereas `176–185` correctly retains an unlocked sidecar. Optional comment-only clarification; no behavior change requested.

Literal non-mutating pipeline control (no suite, fixture or writer executed), command **exit 0**:

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PROBE'
import pathlib, subprocess
data = pathlib.Path('TESTS-RESULTS/2026-10-01+GH-909/gh268-blocker/template-input.txt').read_bytes()
assert len(data) == 339968
cases = [('old_present', 'grep -Fq "EVERY turn, not just the first"', 141),
         ('fixed_present', 'grep -F "EVERY turn, not just the first" >/dev/null', 0),
         ('fixed_absent', 'grep -F "ABSENT-GH909-ORACLE" >/dev/null', 1)]
for name, grep, expected in cases:
    r = subprocess.run(['bash', '-o', 'pipefail', '-c',
        'rendered="$(cat)"; printf "%s" "$rendered" | ' + grep],
        input=data, capture_output=True)
    print(name, 'rc='+str(r.returncode), 'stderr='+repr(r.stderr.decode()))
    assert r.returncode == expected
PROBE
```

Whole artifact, production writer and all four changed suites swept; no additional blocking pre-existing defects found in this bounded scope. The inherited unsafe mktemp/cleanup patterns in the three completion suites remain subject to disposable-full-clone execution. Graph inventory was fully paginated (77 projects) with no matching review worktree; canonical XYZ-forge generation `2026-09-01T15:54:30Z` is another checkout. Coverage checked all five source paths but cannot attest this generation; full current source reads supplied evidence. No git commands, validate.sh, test suites, pytest or executable fixtures ran here. Total-cap stress, Linux execution, final full gate and rollout quiescence remain unverified in this turn.

Relay closed (Approved), no further review turn needed. Handing the completed token back to Producer (claude-a) for the required disposable-clone full gate and exact-head evidence before publication/deployment.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
