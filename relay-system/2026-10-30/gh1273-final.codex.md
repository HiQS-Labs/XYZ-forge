# RELAY · GH-1273 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
-->

NEXT: Producer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh-1273-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1273-RELAY-SEPARATORS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1273-RELAY-SEPARATORS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-30
- Definition of Done: Review full diff origin/development..HEAD, issue #1273, plan, utils/py/relay_attest.py, utils/py/relay_drive.py and committed TESTS-RESULTS/2026-10-30+GH-1273 evidence. Does separator-only fallback preserve literals/history, coordinates and loader compatibility, wrong/empty/failed reviews, raw evidence and warning? Are ratings grounded and scope surgical? No new suites/gates; local CLI operational envelope, commensurate complexity. Flag actual defects with falsifiers. Mechanical verdict repair deferred after done-token trace.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: One observed literal-history bypass and one observed separator-only false rejection in the new fallback. Full seeded plan and both runtime files swept; source-only review and in-memory probes, not a suite rerun. Changes required before approval.
swept file: yes

- [Blocker] **B1 — blank runs inside indented literals are not preserved** (`utils/py/relay_attest.py:176-188`; consumed at `utils/py/relay_drive.py:722-738`). Only immediate neighbors protect an empty line. An interior blank in a longer run between two indented code lines becomes optional, so deleting that literal byte is accepted as harmless history drift. The driver then takes the returned offset, emits the harmless-separator warning and proceeds toward attestation. Protect the entire blank run inside an indented literal context (or conservatively refuse this ambiguity), retaining ordinary separator tolerance. Record this negative control in the existing manual evidence; no new suite/gate.
  Observed input: `pre=b"STATUS: Open\n\n    x\n\n\n\n    y\n"`; post deletes one of the three blank lines between `    x` and `    y`, then appends a substantive PASS review. These are literal blank lines between indented code lines, not section separators.
  Affected scope: separator fallback for blank runs bounded by indented code/literal lines; this request does not broaden normalization to other whitespace.
  Falsifier: the exact input below must return `None`; an ordinary prose separator deletion must still return a post-stream boundary, and a fenced literal deletion must remain refused. If that first input already returns `None` on the candidate, this finding is resolved.
  Probe command (with `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR="$PWD/.relay-scratch/tmp"`):
  ```sh
  PYTHONPATH=utils/py python3 -c 'import relay_attest as a; p=b"STATUS: Open\n\n    x\n\n\n\n    y\n"; q=p.replace(b"\n\n\n\n",b"\n\n\n")+b"\n### Reviewer (codex)\nVERDICT: PASS\nBasis: source.py:1\n"; print("strict=",a.canonical_bytes(q).startswith(a.canonical_prefix(p,q)),"fallback=",a.separator_prefix_end(p,q))'
  ```
  Exit status: **0**. Decisive output: `strict= False fallback= 23` (expected fallback `None`). This is an observed helper failure; the driver consequence is source-traced, not an end-to-end run.

- [Should] **S1 — citation context remains positionally misaligned after a separator edit** (`utils/py/relay_attest.py:146-149,194-199`). The fallback canonicalizes PRE using POST line indices before matching separator-normalized history. Removing an earlier ordinary blank shifts the citation window: PRE retains an old `[Pass]`, while POST carries the harness's legitimate downgrade, so the fallback still refuses harmless drift. Align the citation context to corresponding historical lines within the fallback while keeping ordinary canonical bytes and persisted coordinates unchanged, as the plan's Recon and bet requires. Record the control in the existing manual evidence.
  Observed input: `pre=b"STATUS: Open\n\n[Pass] claim\n\n\n\nfile.py:1\n"`; post changes STATUS, removes only the blank immediately after STATUS, appends a valid review and carries the expected uncited-claim downgrade. The citation is four lines after the historical claim, outside the default three-line window in both actual histories. PRE's shifted context incorrectly sees it within three.
  Affected scope: separator-only edits before citation-sensitive historical lines, with the default citation window; not unrelated citation-policy changes.
  Falsifier: the exact input below must return a boundary and retain the substantive appended review; a historical `FAIL`→`PASS` rewrite or deleted sentence must still return `None`. If it already accepts this separator-only input without relaxing those negative controls, the request is unnecessary.
  Probe command (same environment):
  ```sh
  PYTHONPATH=utils/py python3 -c 'import relay_attest as a; p=b"STATUS: Open\n\n[Pass] claim\n\n\n\nfile.py:1\n"; q=(p.replace(b"Open\n\n",b"Approved\n")+b"\n### Reviewer (codex)\nVERDICT: PASS\nBasis: source.py:1\n").replace(b"[Pass]",a._UNCITED); print("strict=",a.canonical_bytes(q).startswith(a.canonical_prefix(p,q)),"fallback=",a.separator_prefix_end(p,q)); print("pre=",repr(a.canonical_prefix(p,q))); print("post=",repr(a.canonical_bytes(q)))'
  ```
  Exit status: **0**. Decisive output: `strict= False fallback= None`; PRE contains `[Pass] claim`, POST contains `[Unverified \xe2\x80\x94 no citation] claim`. No substantive history edit caused the mismatch.

- [Pass] **Existing writer and record layout are reused.** Strict comparison remains first; fallback supplies only `added_start`; the same canonical post bytes, digest, trailer and writer are used (`utils/py/relay_drive.py:719-777`). `load` still checks that byte range, digest and immediate trailer (`utils/py/relay_attest.py:363-380`). Raw relay text is not rewritten by the fallback. This is source inspection; fallback driver execution and final gate remain **[Unverified — needs clone run]** in this turn.
- [Pass] **Supplied evidence is nonempty and matches its manifest.** A read-only Python probe parsed all six entries in `TESTS-RESULTS/2026-10-30+GH-1273/provenance.jsonl`, read each named artifact and compared `hashlib.sha256(data).hexdigest()` to `sha256`; exit **0**, six `hash-match= True` results. Artifact sizes: `gh505.log` 5682, identities 534 each, `manual-replay.py` 2190, `replay.log` 367, `uncited.log` 1403 bytes. `replay.log` records `separator-delete PASS strict=False offset=60`, both loader round trips and the substantive/fenced negatives. These are supplied clone receipts, not independently rerun suite results; they omit B1 and S1.
- [Pass] **Mechanical recovery deferral is bounded and honest.** The plan explicitly defers it; the driver requires a done token after nonempty review bytes (`utils/py/relay_drive.py:736-741`) and refuses a spent token at startup (`utils/py/relay_drive.py:808-824`). No recovery bypass is inferred. The plan's ratings explicitly call recurrence unknown rather than claiming a measured trend (`.relay-artifacts/GH-1273-RELAY-SEPARATORS.md`, Ratings).

Scope/limits: Read issue #1273, the entire seeded plan, all 490 lines of `relay_attest.py`, all 1172 lines of `relay_drive.py`, the changed separator instructions, and supplied evidence. No additional pre-existing defect found in those runtime file sweeps beyond the findings above. The full `origin/development..HEAD` diff was not independently enumerated: this turn prohibits every git invocation and no diff packet was supplied. Graph discovery was unavailable because its tool required approval under a never-approval policy; direct reads were used. No git command, suite, pytest, or executable fixture was run. Only this relay file was edited. Costly approval-boundary change; the plan's narrow revert remains the rollback. Final gate and candidate-wide diff verification remain with the outer harness/Producer.

Handing off to Producer (claude-a) — resolve B1 and S1, refresh the existing manual receipts in a disposable full clone, then request the next review round.

### Producer · Round 2
B1 Implemented: protect entire empty run by nearest nonblank literal neighbors. Exact reviewer negative recorded in replay-r2.log.
S1 Modified: fallback judges each history at its actual own citation positions, avoiding positional POST lookahead for PRE. Append-sensitive ambiguities refuse conservatively. Ordinary canonical_bytes/record semantics unchanged. Exact reviewer positive passes; substantive negatives remain red.
Real driver/shim separator smoke and loader round trip now retained. Review committed diff packet in TESTS-RESULTS/2026-10-30+GH-1273/review-diff.txt as well as source files. Full gate will run once after Approved.

### Reviewer · Round 2

VERDICT: FAIL
Basis: B1 and S1 are resolved on their exact inputs, but a measured HTML literal-history bypass remains in the separator fallback. Approval must wait for B2 below.
swept file: yes

- [Blocker] **B2 — an inner comment clears protection for an enclosing HTML literal** (`utils/py/relay_attest.py:178-193`). After `<pre>` sets `literal = b"html"`, the `<!-- note -->` branch overwrites it with `None`. A later empty line inside that same `<pre>` becomes optional, so deleting a literal byte is accepted as separator drift. The identical deletion without the inner comment is correctly refused. Keep the enclosing conservative HTML protection when processing comments; no full Markdown parser is needed. Add this negative control to the existing manual evidence in a disposable full clone, without a new suite or gate.
  Observed input: `pre=b"STATUS: Open\n\n<pre>\n<!-- note -->\nalpha\n\nbeta\n</pre>\n"`; POST deletes only the blank between `alpha` and `beta` and appends a substantive PASS review. This blank is inside `<pre>`, not between review sections.
  Affected scope: separator fallback on HTML literal histories containing an inner HTML comment, after which literal empty lines occur between ordinary text lines.
  Falsifier: the exact probe must return fallback `None`, as its without-comment control already does; ordinary prose separator edits must remain accepted and fenced/indented negatives refused. If this candidate already refuses the exact input, B2 is unnecessary.
  Probe command (in-memory helper query only):
  ```sh
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  PYTHONPATH=utils/py python3 -c 'import relay_attest as a; p=b"STATUS: Open\n\n<pre>\n<!-- note -->\nalpha\n\nbeta\n</pre>\n"; r=b"\n### Reviewer (codex)\nVERDICT: PASS\nBasis: source.py:1\n"; q=p.replace(b"alpha\n\nbeta",b"alpha\nbeta")+r; print("strict=",a.canonical_bytes(q).startswith(a.canonical_prefix(p,q)),"fallback=",a.separator_prefix_end(p,q)); c=p.replace(b"<!-- note -->\n",b""); print("without-comment=",a.separator_prefix_end(c,c.replace(b"alpha\n\nbeta",b"alpha\nbeta")+r))'
  ```
  Exit status: **0**. Decisive output: `strict= False fallback= 47` and `without-comment= None`. Expected first fallback: `None`. Root cause: comment handling overwrites the active enclosing HTML state; fix site: the literal-state transition in `separator_prefix_end`; downstream offset/writer changes would merely hide the misclassification. The driver accepts a returned offset and emits its harmless-separator warning before the nonempty-body/done checks (`utils/py/relay_drive.py:722-741`); that consequence is source-traced, not an end-to-end execution here.

- [Pass] **R1 B1 and S1 resolved on the reported inputs.** The exact long-indented-run input now returns `None`; the exact citation-position input returns boundary `56` (`utils/py/relay_attest.py:186-209`). Same in-memory probe, exit **0**: `B1 None`, `S1 56`, ordinary prose deletion `strict=False fallback=20`, fenced deletion `fallback=None`, historical FAIL-to-PASS rewrite and sentence deletion both `None`. These results support the bounded fixes, not blanket literal preservation in light of B2.
- [Pass] **Writer, loader and refusal contracts remain shared.** The strict comparison remains first and fallback changes only the selected start offset (`utils/py/relay_drive.py:719-759`); record/trailer publication remains on the existing path (`utils/py/relay_drive.py:767-782`), and load retains range/digest/trailer checks (`utils/py/relay_attest.py:363-378`). Builder-role and failed turns are rejected before fallback (`utils/py/relay_drive.py:706-717`); empty appended bytes and a non-done token still refuse (`utils/py/relay_drive.py:736-741`). This is source inspection; final candidate execution remains **[Unverified — needs clone run]**.
- [Pass] **Supplied receipts are nonempty and internally intact.** Read-only Python parsed every row of `TESTS-RESULTS/2026-10-30+GH-1273/provenance.jsonl`, read each `artifact`, and asserted nonempty bytes plus SHA-256 equality; exit **0**, `entries= 11`, all eleven `hash-match= True`. The two driver logs retain the warning, terminal approval and `driver separator approval and real loader PASS` (`TESTS-RESULTS/2026-10-30+GH-1273/driver-smoke-r2.log:24`, `TESTS-RESULTS/2026-10-30+GH-1273/driver-adjacent.log:24`). `replay-r2.log` records both loader round trips and B1/S1 controls; it does not cover B2. Existing suite logs are supplied producer evidence, not independently rerun gates for the revised helper.

Scope/limits: Read the whole seeded plan, the supplied runtime/instruction diff packet, all 498 lines of `relay_attest.py`, all 1172 lines of `relay_drive.py`, the whole `new-relay.sh`, and the supplied evidence/scripts as text. No additional pre-existing defect found in those full-file sweeps. The packet contains three runtime/instruction diffs; complete branch-wide path enumeration is not independently established under the prohibition on git. Issue #1273 could not be refreshed (`gh issue view 1273 --json title,body,url`, exit **1**, `error connecting to api.github.com`); this round uses the local plan and prior relay context. Graph access returned `MCP tool call requires approval, but approval policy is never`, so direct reads were used. No git, suite, pytest, executable fixture or model turn was run. Only this relay file was edited. Costly approval-boundary change; the plan's narrow revert remains the rollback. Final gate and complete diff accounting remain with the outer harness/Producer.

Handing off to Producer (claude-a) — resolve B2, record the negative and ordinary-separator controls in the existing manual receipts from a disposable full clone, then request round 3.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
