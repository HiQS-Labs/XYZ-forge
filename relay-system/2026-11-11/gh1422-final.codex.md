# RELAY · GH-1422 final omission QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-11.
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
6. **Commit only the relay file** (`relay(gh-1422-final-omission-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Review packet

Review the committed diff from base `966290ddd8b69fcfd49a9df5e123b118befcd6e1` to HEAD.
Primary artifact: AGENTS.md. Requirements/plan: PROJECT/2-WORKING/GH-1422-AGENTS-SIZE.md.
Evidence: TESTS-RESULTS/2026-11-11+GH-1422/SUMMARY.md and provenance.jsonl.
Perform a dedicated omission-diff: read ORIGINAL AGENTS using git show base:AGENTS.md and
CURRENT AGENTS in full. List every operative original rule/exception/authority boundary with
no equivalent current instruction; report gaps, do not merely summarize. Cross-check mapping.
Check <=28,000 byte target, preserved links/anchors and required reads, no new gate/test machinery,
proper narrow scope, ledger ratings 75/65/50/80 and acceptance claims supported by receipts.
Envelope: documentation compression only; no runtime behavior redesign. Do not demand speculative
enterprise controls. Gate is docs-only; author will retain the full docs gate receipt before publication.
Read-only probes allowed; no suites. Write only this relay. Distinguish pending publication/gate
recording from defects in the artifact. Explicitly report omission review outcome in verdict.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-11-11
- Definition of Done: All operative rules preserved; nonempty AGENTS <=28,000 bytes; accurate mapping, links, scope and evidence.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes
VERDICT: FAIL
Basis: Full original/current omission review found one operative boundary missing. Restore it before approval; no other operative omission or pre-existing defect found in AGENTS.md. This is an Easy documentation correction, with no runtime redesign.

- [Should] Restore the same-PR provenance requirement at `AGENTS.md:119–120` and include it in the requirement map. Original `966290ddd8b69fcfd49a9df5e123b118befcd6e1:AGENTS.md:121–123` requires provenance to be “committed in the same PR”; current text only says “Retain and commit”. A receipt committed separately would satisfy the compressed wording while violating the original evidence boundary. Cheapest fix: add “in the same PR”.
  Observed input: Original operative text “must have its `provenance.jsonl` committed in the same PR” versus current `AGENTS.md:119–120`, which omits “same PR”.
  Affected scope: Runs cited as evidence in issues, PRs, roadmap entries or decisions, exactly the original GH-430 scope.
  Falsifier: An equivalent mandatory instruction requiring same-PR provenance for that scope would make restoration unnecessary. No such equivalent appears in current AGENTS or its mandatory ROUTER/PDDA evidence routing; a receipt committed in a separate PR should remain insufficient.
- [Pass] Other omission groups preserve the operative contract: danger prohibitions and safety read; startup reads; sharing destinations/exclusions and outer-loop limits; runtime opt-out; reconciliation/branch carve-out; principles 1–8 (except the finding above); no-new-test limits; marathon selection; RELEASES ownership; gate/bypass/publication limits; experiment rollback; sandbox mutation guard; canonical policy owners; scratch/PARKED; frozen twins and both historical exceptions; builder/QA separation; HQ; costly kernel surfaces; subagent/full-clone containment, identity and use-boundary checks; invocation audit; macOS/Linux distinction; all five promotion steps; queue limits; development/rename rules; Aider rules; conflict order. Cross-checked `SUMMARY.md` “Original-to-current requirement map” against both complete texts, rather than accepting its equivalence claim. Original fetched read-only through GitHub `fetch_file` at the exact base (blob `bbec1624fe13313fc5637c6387d865f09077d839`), because this turn expressly prohibits git commands. Historical incident detail removal does not otherwise remove an operative rule.
- [Pass] Size/hash match the receipt. Probe: `python3` reading `Path('AGENTS.md').read_bytes()` and printing `len(p), hashlib.sha256(p).hexdigest()`; exit 0; decisive output: `27741 4f2e8449c411b1c57e3cb091148727f3469d8ddac9e1741db87935a12ba1b7e8`. `provenance.jsonl` byte-budget rows also retain original 42,768-byte and empty-input red controls. Current file meets the <=28,000 target.
- [Pass] Local Markdown links and fragments resolve. Probe: `python3` extracting `re.findall(r'\]\(([^)]+)\)', s)`, asserting each local `Path(name).is_file()` and fragment membership in normalized heading slugs; exit 0; decisive output: eight `OK` targets, including `ROUTER.md#role-split` and `WORKTREE-SAFETY.md#12-run-the-full-gate-only-in-a-disposable-full-clone`. Required reads and top-level headings remain. `SUMMARY.md` explicitly limits chain totals to tracked default filenames and states links do not auto-load.
- [Pass] Rated ledger row is consistent: `releases.sql:988` stores GH-1422 ratings `75`, `65`, `50`, `80`, matching the plan's “PRS rationale”. Retained gate receipt `docs-gate.txt` ends “PDDA run complete: no errors, 99 warning(s)”; provenance records exit 0 on `1daf62f6d`. This reviews the retained result, not a new gate execution or final-publication attestation.
- [Unverified — needs harness/clone evidence] Exact committed base-to-HEAD changed-path inventory and gate on the eventual final commit were not independently obtained in this no-git reviewer turn. No suites or executable fixtures were run. No new gate/test machinery appears in the reviewed AGENTS/plan/evidence packet; the harness/author must establish final diff scope and retain the post-correction docs gate before publication. This pending delivery evidence is separate from the textual omission finding.

Handing off to Producer — restore the same-PR boundary, update the mapping as needed, and take your turn in the Producer window.

### Producer · Round 2

Disposition: Implemented the sole Should finding. AGENTS.md principle 6 now explicitly
requires provenance “in the same PR”; requirement map updated. Candidate now 27,756 bytes.
Earlier provenance measurements remain immutable; appended new hash/count receipt.
Re-review the narrow correction and confirm prior omission conclusions still hold.
No runtime changes or new tests. Final push reruns the docs gate on the final commit.

### Reviewer · Round 2

swept file: yes
VERDICT: PASS
Basis: The sole Round 1 omission is resolved. Re-read the complete current AGENTS and original base text (GitHub fetch_file at exact base, blob bbec1624fe13313fc5637c6387d865f09077d839), and cross-checked the requirement map. Omission outcome: no remaining operative original rule, exception or authority boundary without an equivalent current instruction; no additional pre-existing defect found in AGENTS. Approval is textual artifact QA, with final publication evidence still owned by the author/harness.

- [Pass] Same-PR evidence boundary restored: AGENTS.md principle 6 now says “Retain and commit `provenance.jsonl` in the same PR with every run cited in an issue, PR, roadmap or decision”. SUMMARY.md requirement-map row “Operating principle 6” now explicitly says “same-PR committed provenance”. This closes the observed Round 1 counterexample without widening policy.
- [Pass] Updated byte/hash receipt matches current content. Probe command: `python3` reading `p=Path('AGENTS.md').read_bytes()` and the final JSONL row, asserting `0<len(p)<=28000`, byte/hash equality and `'in the same PR' in p.decode()`, then printing length/hash/result; exit 0; decisive output: `27756 b8bf7de266e33184f31fb69d2a21afd62a9951396ccd24f0a418f3d306a466d7 same-PR restored; receipt matches`. Citation: TESTS-RESULTS/2026-11-11+GH-1422/provenance.jsonl final `post-review-byte-budget` row. Earlier measurements remain historical.
- [Unverified — no citation] Whole-file omission sweep preserves the Round 1 enumerated groups, including the narrow frozen-banner/historical-trailer exceptions (AGENTS “Frozen Bash twins”), unavailable-builder stop/independent QA boundaries (“Builder/orchestrator”), per-function resolved-path and clone-identity controls (“Run mutation-heavy suites”), and all five exact-commit promotion steps (“Promotion”). Required startup reads, Markdown target spellings, headings and conflict order remain intact. SUMMARY.md “Original-to-current requirement map” accurately describes these retained obligations; the restored provenance phrase resolves its only previously identified gap.
- [Unverified — needs harness/clone evidence] Exact committed base-to-HEAD changed-path inventory and docs gate on the eventual final commit remain delivery checks, as in Round 1. No git commands, suites, pytest or executable fixtures were run here. The retained docs-gate receipt is historical, not final-head qualification. Author/harness must retain the final docs gate before publication; this does not reopen a textual omission finding. No new gate/test machinery appears in the reviewed artifact packet.

Relay closed (Approved), no further turn needed. Author/harness retains responsibility for final scope/gate recording and publication.


### Attestation · relay-drive — 2026-11-11T22:16:00Z
task: RELAY-gh1422-final
reviewer: codex
status: Approved
reviewed-head: d53a88d60e28f560b6896fea1046609b86eb0a9a
added-range: 11705+2838
added-sha256: 2599b297bffe2b5699790828ff3540779199aa280f05cc2ec1aace6728dd584b
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
