# RELAY · Final QA: recovered primary historical review receipts
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
-->

NEXT: —
STATUS: Approved
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh1063-primary-receipts-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the three historical HiQS receipts under relay-system/2026-10-14/, TESTS-RESULTS/2026-10-15+GH-1063-primary-preservation/, and the appended CHANGELOG entry.
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-15
- Definition of Done: preserve selected historical source bytes and provenance without representing them as fresh approval, publishing current runtime claims, selecting staged reversions, changing runtime or resetting old review budgets.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->


## Bounded preservation review packet

Noel authorized taking over the primary architecture branch, cherry-picking worthwhile
unpublished work and putting it into a PR. A verified local bundle plus staged/unstaged  [Unverified — no citation]
patches/index snapshot preserve the original untouched checkout. The three HiQS historical
records were selected through eleven source-traced cherry-picks onto development dbce58af.
Their bytes exactly match preserved source14b56455, as the recorded hashes/provenance show.
No original architecture/runtime/ledger delta or staged development reversion is part of
this branch; source history remains retained in the protected primary and verified bundle.  [Unverified — no citation]

Review full three preserved records, SUMMARY/provenance and appended CHANGELOG entry.
Confirm that the historical scope, round1/3 or2/3 or1/2 caps, old failures and approvals are
not recast as fresh Forge/HiQS deployment or runtime qualification. Source reviewed-head
IDs name original preserved history, while the cherry-picked identities name the new public
copies. Temporary/machine paths are historical inputs; this PR does not supply those ephemeral
artifacts. Do not require deployments, catalog operations or new tests to preserve these
records. Identify a material problem only with a concrete failing claim/input; unchanged
historical formatting can be a nonblocking Nit with its evidence limit.

Gate/publication is pending and must not be claimed passed. This is a fresh independent
review of preservation, not a reset or continuation of any historical HiQS review. Read-only
source review; only this QA thread is writable. No git commands, tests/validate/pytest,
executable fixtures, external application writes, installation or runtime activation.
Narrow file reads/hashes are allowed. APPEND at absolute EOF using exactly
`### Reviewer (codex) · Round 1`, with literal VERDICT: PASS/FAIL, nonempty Basis and
`swept file: yes/no`. On PASS set STATUS: Approved and NEXT: —, then tick done
RELAY-GH1063-PRIMARY-RECEIPTS-FINAL-20261015. Do not alter the preserved historical records.
The shipped turn shim owns the file-scoped commit.

### Reviewer (codex) · Round 1

Ship for historical preservation.

VERDICT: PASS

Basis: The three complete historical records retain their earlier findings, approval boundaries and review budgets. Their nonempty bytes match the preservation manifest. The new summary and CHANGELOG distinguish historical evidence from present qualification. One inherited attestation-offset nit limits replay of that metadata; preserving it unchanged is appropriate. This approval covers preservation only; publication qualification remains pending.

swept file: yes

Read all three historical receipts in full, the complete SUMMARY/provenance JSON and the complete new CHANGELOG entry. No additional material preservation defect found. The unrelated older CHANGELOG entries and original HiQS implementation were not re-reviewed.

- **[Pass] Historical decisions and caps remain visible.** `relay-system/2026-10-14/hiqs-gh49-plan-qa.md:9` retains `ROUND: 2 / 3`; its initial `VERDICT: FAIL` at line 104, S1/S2 findings at lines 112/117, producer dispositions at lines 133–135 and bounded PASS at lines 142–155 remain present. `hiqs-gh49-final-qa.md:9` retains `ROUND: 1 / 3`, and line 107 expressly excludes deployment and an unrun runtime gate. `hiqs-pr51-glm-qa.md:9` retains `ROUND: 1 / 2`, its ephemeral-evidence nit remains at line 109, and its original attestation remains at lines 118–124. These latter two paths share `relay-system/2026-10-14/`. No historical turn is reopened by this review.
- **[Pass] Current prose does not promote historical approval into current qualification.** `TESTS-RESULTS/2026-10-15+GH-1063-primary-preservation/SUMMARY.md:11–20` says “not fresh approval of Forge or certification of current HiQS deployment/runtime state”, identifies temporary paths as historical inputs, distinguishes original reviewed heads from published copies, and leaves the publication gate required. `CHANGELOG.md:5–12` describes the recovery, excludes staged reversions and explicitly denies fresh approval/runtime qualification. No correction requested.
- **[Pass] Manifest consistency and sensitivity measured.** `TESTS-RESULTS/2026-10-15+GH-1063-primary-preservation/provenance.json:25–39` matches all three actual SHA-256 values and byte counts (13027, 18938, 13152). All historical reviewed-head IDs occur in its source-commit list. The read-only probe below exited **0**; an in-memory added newline was rejected for every file. This establishes consistency with the recorded manifest, not an independent reconstruction of the original Git lineage or bundle.
- **[Nit] Historical attestation ranges are 24 bytes early in the preserved copies.** Concrete inputs: `hiqs-gh49-final-qa.md:129–130` (`7849+4776`), `hiqs-gh49-plan-qa.md:165–166` (`14436+4100`), and `hiqs-pr51-glm-qa.md:123–124` (`7673+5073`), all under `relay-system/2026-10-14/`. Hashing each literal byte range does not reproduce its digest; adding 24 to its start does. The first literal-range assertion exited **1**, `AssertionError`; the bounded follow-up below exited **0** and localized the same offset in all three. This is an inherited replay limitation, not evidence of a failed preservation hash. No byte edit requested: retain the historical metadata and this caveat; do not cite those ranges as freshly valid attestations.

Reproducible read-only probe used for the preceding two findings:

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 - <<'PY'
from pathlib import Path
import hashlib, json, re
m = json.loads(Path("TESTS-RESULTS/2026-10-15+GH-1063-primary-preservation/provenance.json").read_text())
assert len(m["files"]) == 3 and set(m["paths"]) == {f["path"] for f in m["files"]}
for f in m["files"]:
    b = Path(f["path"]).read_bytes()
    assert b and len(b) == f["bytes"] and hashlib.sha256(b).hexdigest() == f["sha256"]
    a, n = map(int, re.search(rb"added-range: (\d+)\+(\d+)", b).groups())
    h = re.search(rb"added-sha256: ([0-9a-f]{64})", b)[1].decode()
    match = lambda d: hashlib.sha256(b[a+d:a+d+n]).hexdigest() == h
    assert not match(0) and match(24)
    assert re.search(rb"reviewed-head: ([0-9a-f]{40})", b)[1].decode() in m["sourceCommits"]
    assert hashlib.sha256(b + b"\n").hexdigest() != f["sha256"]
    print(f'{Path(f["path"]).name}: bytes={len(b)} manifest=match span@recorded=False span@+24=True changed-byte-control=rejected')
print("PASS: 3 nonempty records; manifest identity and historical offset limitation measured")
PY
```

Decisive output (exit **0**):

```text
hiqs-gh49-final-qa.md: bytes=13027 manifest=match span@recorded=False span@+24=True changed-byte-control=rejected
hiqs-gh49-plan-qa.md: bytes=18938 manifest=match span@recorded=False span@+24=True changed-byte-control=rejected
hiqs-pr51-glm-qa.md: bytes=13152 manifest=match span@recorded=False span@+24=True changed-byte-control=rejected
PASS: 3 nonempty records; manifest identity and historical offset limitation measured
```

Limits: Graph Verify startup found no index for this worktree; the nearest Forge project is another checkout, generation `2026-09-01T15:54:30Z`. Coverage for all six evidence paths was missing or excluded, so direct file reads supplied the evidence. Original source-tip equality, bundle validity, cherry-pick ancestry and branch-wide exclusion of runtime/staged changes remain producer-reported, not independently rederived under the no-Git boundary. No Git command, suite, executable fixture, external operation or artifact edit was performed. Publication/harness qualification is **[Unverified — needs clone run]** and remains separate. Only this QA thread was edited.

Relay closed (Approved), no further turn needed. Producer (codex-producer) receives the preservation review; the harness owns the file-scoped commit and subsequent gate.
