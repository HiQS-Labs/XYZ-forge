# RELAY · GH-1400 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-09.
-->

NEXT: Producer
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-1400-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/2-daily/flywheel/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-11-09
- Definition of Done: Approve the delivered instruction-only GH-1400 subset against the plan, retained textual smoke and existing documentation gate; no claim that the entire arc is finished.

## Review packet

Operational envelope: local single-operator routing skill. Read whole flywheel SKILL,
`git diff origin/development -- skills/2-daily/flywheel/SKILL.md`, canonical
`PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md`, recon and
`TESTS-RESULTS/2026-11-09+GH-1400/` evidence. Existing plan QA Approved.

1. Does each delivered requirement match the plan, retaining GH-1399 enforcement and GH-1401/upstream/trial limitations?
2. Are batch approval, exact heads, native event/timer capability, changed-head recovery and operation-owned accounting truthful against existing owners?
3. Does preparation remain a signal requiring explicit selection/revalidation, with no invented label consumer?
4. Is this surgical/DRY, with no new runtime, suites, gates, scheduler or speculative machinery?
5. Do retained manual smoke and gate evidence substantiate exactly the claims made, and does PRS retain 75/60/50/80 with no override?
Report omission-diff against the requirements table. Do not run suites in the reviewer worktree.
Review whole skill for concrete pre-existing defects; grade against commensurate scope.

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
Basis: Ship the delivered instruction-only subset. No blocking omission against the four-row requirements table; broader enforcement, upstream implementation and real-work qualification remain open.
swept file: yes

- [Pass] Batch landing: artifact says “explicit batch list”, “neither a ready PR nor a `--prs` pin grants approval”, and “A repaired/moved head needs fresh eligibility, review/approval as applicable and a new pin”. Matches merge-cleanup SKILL.md:236–249 and retains its landing-plan checkpoint. No new landing authority.
- [Pass] Event continuation: “where the harness provides it”, live-head/terminal-result verification, capability/readback checks and “continuation is unarmed” cover supported and unsupported harnesses. Matches handsfree SKILL.md Start steps 2–3; no watcher or scheduler is claimed installed.
- [Pass] Accounting: “Before a repair, use that owner's existing reservation/wrapper” and “hold the repair” preserve merge-cleanup SKILL.md:336's durable per-PR reservation and distinguish lane attempts. “Universal push/gate enforcement is proposed in GH-1399” explicitly retains the enforcement limitation.
- [Pass] Upstream: “Prepared intake is a signal for selection” and “neither automatic Jog selection nor execution approval” retain selected-owner revalidation and GH-1401 independence. Omission-diff: none in the delivered requirements; GH-1399 enforcement, GH-1401 runtime and GH-1386 supervision/cost trial are deliberately undelivered.
- [Pass] Whole-file sweep found no concrete pre-existing defect requiring correction within this instruction scope. Existing 10days explicit-invocation exception, marathon confirmation, Jog recovery order, independent review, per-PR merge approval and explicit-only deployment remain intact. Artifact completion text says “A prepared plan, open PR, healthy process or elapsed window is not completion”. No new runtime, suite, gate or writer is prescribed.
- [Pass] Retained evidence is correctly scoped: SUMMARY.md labels all five scenarios “PASS (textual)” and disclaims executed landing/cost savings. Read-only probe (exit 0): `python3` with `hashlib.sha256(Path('.relay-artifacts/SKILL.md').read_bytes()).hexdigest()` returned `df6430db13f6db9f460f86b2891a2dfe0fe6c74f28abfc890c26a56b93cded15`, matching provenance.jsonl; byte comparison with source returned `True`. Using `gzip.open(.../pdda.log.gz, 'rt').read()` showed “PDDA run complete: no errors, 659 warning(s)”; JSON before/after comparison returned `True`. This inspects retained evidence, not a fresh gate run.
- [Pass] Read-only PRS probe (exit 0): `sqlite3.connect('file:releases.db?mode=ro', uri=True)` and `select * from roadmap_items where gh_number=1400` returned row 476, ratings `75/60/50/80`, `rating_ovr: null`, status `in-progress`. Plan's bounded rating claim is supported.
- [Unverified — needs clone run] No suites, fixtures or runtime trial were executed here. Gate receipt reports revision `37119562c`; harness owns post-turn qualification. No git command was run under the explicit reviewer restriction, so the requested origin/development diff was not independently queried. Approval covers the whole seeded artifact and retained instruction evidence, not final commit/remote state or throughput.

Relay closed (Approved), no further turn needed. Harness owns the file-scoped commit; reviewer ran no git commands.


### Attestation · relay-drive — 2026-11-10T05:12:51Z
task: RELAY-gh1400-final
reviewer: codex
status: Approved
reviewed-head: 2bb92f56f0a793325aa5563ff67f8c9a156e6f0b
added-range: 6997+3468
added-sha256: af0a99ded4b0e7b90a0a8ede3097d38511caabab0bae1032f215f018022606e1
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
