# RELAY · GH-974 deferred HiQS intake QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-05.
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
6. **Commit only the relay file** (`relay(gh-974-deferred-hiqs-intake-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh974-review.md** — the read-only path that
  `relay-drive.sh --artifact-file temp/gh974-review.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-05
- Definition of Done: deferred native #974 intake; specific advisory-only revisit criteria; deterministic boundaries; retained verification and no unrelated ledger-row edits.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1
swept file: yes
VERDICT: FAIL
Basis: The complete seeded artifact and intake document satisfy the deferred advisory scope; one requested ledger-delta criterion remains unverified. No observed substantive or pre-existing defect in those files. This verdict requests evidence, not implementation.

- [Pass] Deferred scope and live-evidence prerequisite are explicit: PROJECT/1-INBOX/GH-974-REVISIT-ADVISORY-JEV-SCREENING.md:47 says “No classifier implementation is authorized”; :55 says the instruction chains “are not verified HiQS catalog recipes”; :59 and :74-82 require recorded recurring reviewer burden after real chain evidence. No change requested.
- [Pass] The first comparison requires static rules, existing agent-assisted review and human-labelled held-out HiQS data (:61, :75-77). The same :61 rejects Needle work-purpose scores as domain evidence. Deterministic resolver/policy, traces/digests, attestations and publication are protected at :63. No change requested.
- [Pass] releases.sql:805 contains the native #974 row, paused in “Deferred · vision”, exact issue/doc/Needle-fork links and 20/10/50/55 ratings; provisional status and rationale are explicit in the intake document :14 and :88. Narrow probe command: `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` with an in-memory SQLite table derived from the dump's roadmap_items column list, executing only its INSERT lines, selecting `gh_number='974'`, and asserting count=1, links, marker/section and four ratings. Exit 0; decisive output: “dump rows #974=1; native links, paused deferred section, ratings 20/10/50/55: OK”. This checks the current dump, not its delta.
- [Pass] Retained receipts support the scoped claims in CHANGELOG.md:5 and TESTS-RESULTS/2026-10-05+GH-974/SUMMARY.md:3. provenance.jsonl:1 records complexity 9, exit 1 and “must be an integer 1-5”; :2 records the restored passing frontmatter check; :3-7 record the remaining checks/readback. The same Python probe parsed all seven JSONL records and asserted the red status/message and subsequent zero statuses: exit 0, “retained JSONL receipts=7; invalid complexity 9 exits 1; six subsequent records exit 0”. These are retained producer receipts, not fresh suite execution. An initial attempt to execute the entire data-only dump in empty in-memory SQLite exited 1 (“no such table: schema_migrations”); the corrected roadmap-only probe above avoids requiring a schema migration and makes no RELEASES consistency claim.
- [Should] Supply retained base-to-candidate ledger-delta evidence before approval. .relay-artifacts/gh974-review.md:11 explicitly requires “without unrelated row edits”, but provenance.jsonl:6 supplies only current-row readback. Neither a base dump nor a diff is retained in the supplied evidence. This turn prohibits Git commands, so the requested diff at artifact :5 was not run. Concrete fix: producer/harness should retain the exact-base comparison with command, base/candidate identifiers, exit status and decisive output, showing unrelated roadmap rows unchanged and explaining any expected receipt/generation additions.
  Observed input: artifact :11's no-unrelated-row-edit criterion paired with provenance.jsonl:6's single-row readback; probe output: “LIMIT: no base dump comparison available; unrelated-row delta not measured”.
  Affected scope: evidence for this #974 intake delta only; no runtime behavior change.
  Falsifier: a retained comparison against the stated origin/development base showing exactly the #974 roadmap addition, no unrelated roadmap modifications/removals, and only attributable ledger metadata/receipts would close this finding.
- [Unverified — needs clone run] No validate.sh, test/*.sh, pytest or executable fixtures were run. The harness gate remains separate. Graph project listing had no index for this worktree; the nearest XYZ-forge graph generation was 2026-09-01 and coverage marked these paths missing/excluded/changed, so claims above use direct local document/dump reads, not graph completeness.

Handing off to Producer (codex-producer) — retain the ledger-delta evidence, disposition the finding, then reopen review.

### Producer · Round 2

Implemented the Round 1 evidence request. `TESTS-RESULTS/2026-10-05+GH-974/ledger-delta.json` retains the exact origin/development base and candidate content commit identifiers, every changed table row and manual assertion output. Compared all user tables in read-only SQLite: only the #974 roadmap addition, generation advance and two attributable receipts/work events differ; no unrelated rows changed or removed. `provenance.jsonl` and `SUMMARY.md` record the comparison. No implementation or policy change.

Handing off to Reviewer (codex) — review the new retained ledger delta and close if satisfied.

### Reviewer · Round 2
swept file: yes
VERDICT: PASS
Basis: Reviewed the whole seeded artifact, complete intake document, scoped changelog entry and all retained GH-974 evidence. Round 1's evidence request is satisfied by the retained exact-base comparison. No substantive or pre-existing defect found in the reviewed scope. Approval covers deferred intake; the harness gate remains separate.

- [Pass] Deferred authority and live-evidence prerequisite remain explicit: PROJECT/1-INBOX/GH-974-REVISIT-ADVISORY-JEV-SCREENING.md:47 says “No classifier implementation is authorized”; :55 says the instruction chains “are not verified HiQS catalog recipes”; :59 and :74-84 require recurring measured burden, baselines and held-out human labels before promotion. No change requested.
- [Pass] Advisory contribution screening is bounded at intake :61; the same span rejects Needle work-purpose scores as evidence for HiQS. Intake :63 protects resolve/lookup/explain, policy, traces/digests, attestations and publication. No change requested.
- [Pass] Close Round 1's ledger-delta finding. TESTS-RESULTS/2026-10-05+GH-974/ledger-delta.json:2 names base 442ea913ee5e2fb3d6e050a63c6d90ff07865eb6; :3 names candidate content commit bbbd5a5c9a7bbf4b580beffef2ac88a2b40bef09; :4 records 16 tables. Its complete delta contains only generation 1414→1416 (:6), one native #974 addition (:47), two #974-targeted operation receipts (:22) and two corresponding #974 work events (:76). The assertion at :102 states “no unrelated roadmap row changed or removed”; provenance.jsonl:8 retains command, identifiers, exit 0 and decisive output. This is retained producer exact-base evidence, not a freshly rerun base comparison. No change requested.
- [Pass] Narrow read-only corroboration: command `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'` parsed ledger-delta.json and all provenance records, opened `sqlite3.connect('file:releases.db?mode=ro', uri=True)`, checked table count, compared every retained added row by key/id with the current database, and asserted native-row uniqueness, scope, ratings and receipt/event transaction attribution. Exit 0; decisive output: “16 user tables; all 6 retained candidate rows match read-only DB; exactly one deferred native #974 row; two #974 receipts/events attributable.” Evidence spans: ledger-delta.json:14, :24, :49 and :78. No base DB is seeded here; the exact-base assertion is accepted as the retained receipt above.
- [Pass] Verification remains scoped and supported: CHANGELOG.md:5 and SUMMARY.md:3 match provenance.jsonl:1-7; :1 records invalid complexity 9 exiting 1, :2 records the restored passing check. The same probe exits 0 with “8 retained receipts: red control exit 1; seven subsequent exit 0; base/candidate identifiers agree.” SUMMARY.md:5 accurately points to the new delta evidence. No change requested.
- [Unverified — needs clone run] No validate.sh, test/*.sh, pytest or executable fixtures were run. No Git commands were run. Graph tools are unavailable in this turn; findings use direct local document/evidence reads and the read-only SQLite probe. External PR status claims at intake :55 were not independently refreshed in this bounded local review.

Relay closed (Approved), no further turn needed. Token completion returns control to the producer/harness for its file-scoped commit and separate gate.


### Attestation · relay-drive — 2026-10-05T21:31:52Z
task: RELAY-GH974-INTAKE
reviewer: codex
status: Approved
reviewed-head: ba20f6802710383e48514276bc9a8f38e429f57e
added-range: 10280+3419
added-sha256: aef8d63f0cd52e79b643d2df2980dccbec9b7cbd3507954be8ffa682b8d6cc83
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
