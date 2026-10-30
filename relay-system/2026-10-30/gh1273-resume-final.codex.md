# RELAY · GH-1273 authorized final QA resume
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 5

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
6. **Commit only the relay file** (`relay(gh-1273-authorized-final-qa-resume): <role> r<N>`); no push. **Stop** and report one line.
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
- Definition of Done: Fresh user-authorized final QA, max five rounds. Previous final relay escalated; no approval reused. Read complete plan, issue #1273, utils/py/relay_attest.py and relay_drive.py, new-relay.sh; runtime diff TESTS-RESULTS/2026-10-30+GH-1273/resume-diff.txt; all retained evidence, especially b3-controls.log and replay-resume.log. Is B3 fixed without weakening historical/literal protections, canonical offsets/loaders, warning/raw evidence, invalid review refusal? Are all requirements satisfied, ratings grounded, scope surgical? Existing local CLI envelope; no new tests/gates. Reject speculative scope expansion, require concrete falsifier for findings. Final classified gate follows Approved; no merge.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: Fresh authorized review of the complete seeded plan, live issue #1273, all three runtime/scaffold files and retained evidence. B3 is resolved on its exact failing input with a witnessed prior-behavior control. No Blocker or Should finding remains. This approves final QA; the classified clone gate and ready-PR workflow remain outstanding, with no merge authorized.
swept file: yes

- [Pass] **B3 resolved without normalizing original bytes.** `utils/py/relay_attest.py:194` uses `expandtabs(4)` only to classify nearest nonblank neighbors; retained lines and offsets still use the original bytes (`utils/py/relay_attest.py:198`). The exact mixed-indent deletion refuses; equivalent two-/three-space-tab, four-space and initial-tab inputs refuse, while ordinary prose still yields boundary 20. Retained red/candidate evidence agrees (`TESTS-RESULTS/2026-10-30+GH-1273/b3-controls.log:1`, `TESTS-RESULTS/2026-10-30+GH-1273/replay-resume.log:12`). Independent read-only command, with the previous neighbor predicate restored solely in memory:
  ```sh
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  PYTHONPATH=utils/py python3 - <<'PY'
  import relay_attest as a
  from pathlib import Path
  s=Path("utils/py/relay_attest.py").read_text()
  old='n.expandtabs(4).startswith((b"    ", b">", b"<"))'
  assert s.count(old)==1
  red={}
  exec(compile(s.replace(old,'n.startswith((b"    ", b"\\t", b">", b"<"))'),"<B3-prior>","exec"),red)
  r=b"\n### Reviewer (codex)\nVERDICT: PASS\nBasis: source.py:1\n"
  for indent in (b" \t",b"  \t",b"   \t",b"    ",b"\t",b""):
      p=b"STATUS: Open\n\n"+indent+b"alpha\n\n"+indent+b"beta\n"
      q=p.replace(b"alpha\n\n",b"alpha\n")+r
      print(repr(indent),"prior=",red["separator_prefix_end"](p,q),"candidate=",a.separator_prefix_end(p,q))
  PY
  ```
  Exit **0**. Decisive output: mixed forms `prior=24/26/28 candidate=None`; four-space and tab controls `prior=None candidate=None`; prose `prior=20 candidate=20`. Root cause was a byte-prefix indentation classifier missing equivalent tab columns; the fix changes that classifier, leaving downstream coordinates and writers alone.

- [Pass] **Historical/literal protections and canonical coordinates remain intact on the examined controls.** The fallback compares each actual history after its own citation downgrade, retains fenced content and nearest literal neighbors, and preserves enclosing HTML state across comments (`utils/py/relay_attest.py:159`, `utils/py/relay_attest.py:179`, `utils/py/relay_attest.py:203`). Retained resume receipts cover historical verdict rewrite, sentence deletion, fenced/indented blanks, B1 long blank runs, S1 citation positioning, B2 HTML comments, legacy and fallback loader round trips (`TESTS-RESULTS/2026-10-30+GH-1273/replay-resume.log:1`). Ordinary canonicalization is unchanged; the driver tries exact prefix first and uses the returned original post-stream offset only on fallback (`utils/py/relay_drive.py:719`). Loader range, digest and immediate trailer checks remain shared (`utils/py/relay_attest.py:369`). These are bounded controls, not a claim of complete Markdown parsing.

- [Pass] **Warning, raw evidence and invalid-review refusal remain on the existing path.** The driver emits the formatting warning without rewriting the transcript (`utils/py/relay_drive.py:726`); wrong-role/failed turns refuse before fallback, empty appended bytes and non-done tokens refuse afterward (`utils/py/relay_drive.py:706`, `utils/py/relay_drive.py:736`). Supplied clone receipts retain the warning, terminal advancement and real loader success (`TESTS-RESULTS/2026-10-30+GH-1273/driver-smoke-r3.log:11`, `TESTS-RESULTS/2026-10-30+GH-1273/driver-smoke-r3.log:24`), plus candidate focused-suite refusal controls (`TESTS-RESULTS/2026-10-30+GH-1273/gh505-resume.log:44`) and citation results "16 pass, 0 fail" (`TESTS-RESULTS/2026-10-30+GH-1273/uncited-resume.log:19`). These are retained Producer clone runs, not suites rerun in this turn.

- [Pass] **Evidence integrity and scope are bounded.** A read-only Python probe parsed `TESTS-RESULTS/2026-10-30+GH-1273/provenance.jsonl`, then executed `data=Path(row['artifact']).read_bytes(); assert data and hashlib.sha256(data).hexdigest()==row['sha256']` for every row; exit **0**, "provenance entries= 19 all nonempty/hash-match=True". Read-only `tarfile.open`/`extractfile` comparison found packaged `relay-automation/new-relay.sh` byte-identical to source. The supplied resume diff contains only the helper, driver and existing scaffold instruction changes; its sole runtime difference from the prior R3 packet is the mixed-indent predicate. No new suite, gate or controller appears in that packet. The plan explicitly records "trend unknown" and permits splitting mechanical verdict recovery; the live issue permits that split. Done-token requirements and spent-token refusal remain explicit (`utils/py/relay_drive.py:739`, `utils/py/relay_drive.py:824`). The 85/82/50/65 ratings are a stated judgment grounded in the observed stop, not a measured recurrence claim.

Scope/limits: Swept the whole 66-line seeded artifact, all 502 lines of `relay_attest.py`, all 1172 lines of `relay_drive.py`, all 189 lines of `new-relay.sh`, the previous escalated relay, supplied runtime/scope packets and all retained evidence/scripts as text. No additional pre-existing defect found in those full-file sweeps. Read issue #1273 through the GitHub connector. Graph lookup returned "MCP tool call requires approval, but approval policy is never"; direct reads were used. Complete branch-wide diff fidelity is not independently established under the no-git restriction. No git command, suite, pytest, executable fixture or model turn was run. Only this relay file was edited; scratch directory creation stayed under `.relay-scratch/`. Costly shared approval-boundary change; narrow revert is the rollback. Final classified gate on the final candidate remains **[Unverified — needs clone run]**, intentionally after this approval under the authorized workflow. This is a seeded-artifact review, not merge authorization.

Relay closed (Approved), no further turn needed. Producer/outer harness continues with the final classified gate, then the authorized gated push and ready PR to development; no merge.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
