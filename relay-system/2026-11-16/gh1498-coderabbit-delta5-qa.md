# RELAY · GH-1498 third-pass QA (re-run)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-17.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(gh1498-coderabbit-delta5-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **skills/2-daily/pr-minder/scripts/pr_minder.py** (review `git diff a37ecbf67..a88d70a80`).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-17
- Definition of Done: `git diff a37ecbf67..a88d70a80` correctly fixes CodeRabbit's third-pass findings and adds the requested evidence, with no regression.

## Context and questions

This re-runs `gh1498-coderabbit-delta4-qa.md`. Your PASS there was reverted because the producer edited evidence files in the clone during your turn, and the shim attributed those edits to you. That was the producer's mistake, not a finding. The tree is now committed and clean.

**Envelope:** a manual local CLI. No new tests (GH-831).

**Product code** (unchanged since `4080d4b80`):
- the focus filter runs before the `conflict_files` loop (`pr_minder.py` `main`);
- null or malformed `reviewThreads` entries return `(None, False)` (`planner_core.author_activity`).

**Evidence added in `a88d70a80`:**
- **A21:** an async update-branch whose head appears only on the 3rd read is classified `ok`; the red control is a single read.
- **A19e:** gains a red control, a marker-only filter that ignores `viewerDidAuthor`.
- **Claims:** the driver header and README no longer say every assertion has a bad candidate; they list the 4 render/behaviour checks.

Manual check: 30/30. The reviewer-probe provenance request is declined, as before.

Answer, citing `file:line`:
1. Are both code fixes correct, with no regression?
2. Do A21 and A19e exercise the claimed paths, with red controls that fail?
3. Is the decline sound?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: The seeded code fixes preserve the intended CLI behavior, and the added A21/A19e evidence exercises the claimed decisions with effective red controls. No additional concrete pre-existing defect found in the full driver sweep. Approval covers this code/evidence review; final-head gate qualification remains with the harness.
swept file: yes

Read all 571 lines of `skills/2-daily/pr-minder/scripts/pr_minder.py`, the shared activity query and clock, the relevant manual driver and retained results/provenance, and the preceding delta4 relay. Graph tools are unavailable in this session; direct source reads supplied the evidence. No Git executable, network operation, suite, pytest, gate or executable fixture was run. The only tracked edit is this relay file.

- [Pass] **Both bounded code fixes are correct.** `skills/2-daily/pr-minder/scripts/pr_minder.py:523–533` retains assessment of every PR for stack inheritance, then filters before fetching conflict files and rebuilding the selected comment. Explanation follows enrichment at `:535–539`. `skills/3-weekly/weekly-planner/scripts/planner_core.py:1322–1329` returns unknown for null thread/inner-comment entries; valid entries still contribute timestamps. Unknown rows remain report-only at `pr_minder.py:276–278`. No requested correction.

- [Pass] **Independent narrow probes support the code review.** Commands: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 - <<'PY'` and a second `python3 - <<'PY'`, each exit **0**. Inline Python AST-compiled only the seeded `author_activity`/parsing helpers, `apply_row`, and `main`; all readers, mutation calls, receipts and sleeps were in-memory substitutes, with no subprocess or external side effect reachable. Decisive asserted output: `null-thread/null-comment -> (None, False); valid empty thread preserves timestamp`; `['--pr', '150', '--json'] lookup=[150] assessed=[150, 151] rc=0`; `['--explain', '151'] lookup=[151] assessed=[150, 151] rc=0`; `['--pr', '999'] lookup=[] assessed=[150, 151] rc=2`; unfiltered JSON looked up both PRs. The explanation contained `own-conflict.txt` in both its conflict list and rebuilt comment. These measure the wiring at `pr_minder.py:523–539`, rather than live Git conflict discovery.

- [Pass] **A21 exercises async polling and rejects the single-read control.** `TESTS-RESULTS/2026-11-16+GH-1498/manual_check.py.txt:873–882` seeds two stale reads, invokes apply with five reads, and requires exactly one successful result with `head_after == "h160-synced"`; its bad candidate permits only one read. The fake returns stale heads only on queried head reads (`:53–58`), after update-branch stores the old head (`:60–67`). Production uses bounded read polling without repeating the mutation at `pr_minder.py:437–449`. The first AST probe above asserted `A21 decision: width=5 reads=3 outcome=ok mutation_calls=1` and `A21 decision: width=1 reads=1 outcome=uncertain mutation_calls=1`. Recorded outcomes are at `manual-check.log:31–33`. No requested correction.

- [Pass] **A19e's red control is effective; evidence claims are now accurate.** `manual_check.py.txt:802–821` supplies a recent marker comment with `viewerDidAuthor=False`, then removes marker comments in the bad candidate before rerunning the same assertion. This targets the ownership predicate at `planner_core.py:1310–1312`. The first AST probe asserted `A19e decision: foreign marker -> 2026-11-16; marker-only control -> 2026-09-01 (rejected)`. The second probe parsed nonempty retained results and asserted `retained JSON: 30 PASS; A19e/A21 bad_rejected=true, bad_crashed=null`. `manual_check.py.txt:180–196` treats crashed controls as failures. Its header (`:2–5`) and `TESTS-RESULTS/2026-11-16+GH-1498/README.md:7–8` explicitly exclude A12b/A18/A19d/A20a from red-control claims. No requested correction.

- [Pass] **The reviewer-probe provenance decline is sound for this turn.** The current operator instruction requires scratch-only probes and quoting their command, status and decisive output in the finding; it expressly forbids editing evidence artifacts. Those probe details are recorded above. Producer evidence is separately retained: `TESTS-RESULTS/2026-11-16+GH-1498/provenance.jsonl` contains the `"id": "A1-A21"` record identifying product revision `4080d4b80`, the manual command, 30 passes and the two red controls. That revision identifies unchanged product code, not an assertion that the later evidence commit itself was gated. No new producer provenance entry is required for these reviewer-only probes.

- [Unverified — needs clone run] The complete manual driver and final-head gate were not rerun here. The inspected 30/30 receipt is producer evidence; executable fixtures and qualification belong to the disposable-full-clone harness after this turn.

Relay closed (Approved), no further turn needed. The token is closed with `done`; the harness owns the file-scoped commit.


### Attestation · relay-drive — 2026-11-17T09:47:09Z
task: RELAY-gh1498-coderabbit-delta5
reviewer: codex
status: Approved
reviewed-head: 4d16768574592b457e25ac1de9c8f798eb4dec39
added-range: 7004+5048
added-sha256: 8a4a64f527065070ecdaee62aaf972e7ee5db3cddf4b90c7f56f8df3d1dc5438
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
