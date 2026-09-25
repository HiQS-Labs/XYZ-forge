# RELAY · PR 827 Fable high review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-25.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 2

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
6. **Commit only the relay file** (`relay(pr-827-fable-high-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh825-pr827-f0e68399.patch** — the read-only path that
  `relay-drive.sh --artifact-file temp/gh825-pr827-f0e68399.patch` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: claude   ·   Producer: codex
- Started: 2026-09-25
- Definition of Done: Independently review PR #827 at head `f0e683992560ed03cd51c9cf70b82ae7ccba72b2` against `development` base `31a42867521577e58220cd194d442212c609b7ca`. Identify concrete correctness, naming, safety, or verification gaps; approve only if the whole branch meets its stated requirements.

## Review packet

Operational envelope: a portable Markdown `handsfree` skill and two operator-requested skill follow-ups in one PR. Use Claude Code Fable 5 at high effort. Review the complete seeded patch and the full current versions of changed files. The PR is draft because its follow-up commit changed a skill installer and an existing test while the operator restricted local verification to the PDDA Markdown/text gate. Do not treat the earlier full gate at `9b3a780d` as proof for this head. Do not run `validate.sh`, `test/*.sh`, pytest, or executable fixtures in this relay worktree; use only read-only source inspection and narrow non-mutating probes as the relay policy permits.

Read `PROJECT/2-WORKING/GH-825-HANDSFREE-SKILL.md`, `skills/1-hourly/handsfree/SKILL.md`, `skills/1-hourly/start-task/SKILL.md`, `skills/2-daily/where-are-we-at/SKILL.md`, its `install.sh`, `test/gh798-status-skill.sh`, `utils/ci-route.sh`, `githooks/pre-push`, and the `ARCHITECTURE.md` and `CHANGELOG.md` entries. Use the seeded patch for exact changed lines. The original Codex QA receipts are `relay-system/2026-09-25/gh825-plan-r2.codex.md` and `gh825-final.codex.md`; both predate the follow-up commit.

Questions:
1. Does `handsfree` meet the 10-minute, at-most-three-hour native same-conversation wake requirement, including stop/cancel uncertainty and the ignored note? Cite concrete lines for any gap.
2. Does `start-task` correctly use the existing docs route for Markdown/text-only diffs while retaining the tiered/full route for scripts, tests, DB files, and renames? Is any instruction internally contradictory or easy to misapply?
3. Is `where-are-we-at` fully renamed for actual skill discovery and installation? Check the installer target, catalog entry, trigger text, and updated existing test assertions. Find any live old-name reference that would break use.
4. Does the PR's test and review evidence support its current draft status, and what exact check remains before merge readiness? Do not request a new framework or speculative tests.
5. Is the 13-file PR diff surgical and coherent? Identify any concrete unintentional change or latent defect in the touched files.

Give one `VERDICT: PASS`, `FAIL`, or `PARKED`, a concise Basis, `swept file: yes/no`, and graded findings with file:line citations. For every behavior-change `[Blocker]` or `[Should]`, include `Observed input:`, `Affected scope:`, and `Falsifier:`. Write only this relay thread; do not edit implementation files or the PR.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · claude

VERDICT: PASS
Basis: All five packet questions close in the branch's favor at the declared read-only inspection level. The handsfree skill implements the 10-minute / ≤3-hour same-conversation wake with honest capability gating and explicit cancel-uncertainty handling; the start-task routing text matches the repo's real classifier and push hook exactly; the `where-are-we-at` rename is complete with no live old-name reference; the 13-file diff is surgical. Draft status is correct and its remaining check is exact: the committed full-gate evidence is pinned to `9b3a780d` while this head's own diff (edited test + renamed installer script) classifies tier 3, so one full qualifying gate (`bash ci-local.sh`) on `f0e683992560` in a disposable full clone with a fresh provenance receipt, then hosted CI on the pushed head, is what stands between draft and merge-ready. This approval is not a live-scheduler, gate, or hosted-CI attestation.
swept file: yes

Swept the complete current versions of every text file the PR touches (handsfree/SKILL.md all 111 lines; where-are-we-at/SKILL.md all 237; where-are-we-at/install.sh all 59; test/gh798-status-skill.sh all 127; the start-task hunk plus surrounding steps 7–8; the ARCHITECTURE/CHANGELOG entries; the GH-825 plan doc; both committed relay receipts; the releases.sql hunks) plus the unchanged routing sources the follow-up's claims depend on (`utils/ci-route.sh`, `githooks/pre-push`). Pre-existing defects: none material; two cosmetic pre-existing nits noted below.

- [Pass] Q1 — wake contract met. Cadence and deadline are recorded up front (`skills/1-hourly/handsfree/SKILL.md:25` "a hard deadline no later than 3 hours later"; `:28` "10-minute cadence"); exactly one job is armed only after same-conversation, cancel, receipt, and active-job readback checks (`:33-38`); the scheduled prompt checks the deadline first (`:70`) and each wake re-checks the wall clock before acting (`:80-81`). Stop/cancel uncertainty: pre-creation refusal leaves the wake unarmed (`:54-55`); attempted-creation with failed receipt/readback requires cancel + inactive proof, else "may still be active" plus the manual stop action, with no replacement job (`:56-61`); terminal stop requires inactive/absent readback and never reports an unproven cancellation as stopped (`:97-104`); no auto-renewal or overlapping loop, deadline holds under delayed wakes (`:105-107`). The note is ignored and collision-safe: `.gitignore:13` is `/temp/`, and the path is `temp/handsfree-YYYY-MM-DD-<session-token>.md`, unique per session (`:26-27`), explicitly subordinate to the issue/plan/CI (`:30-31`). No gap found.
- [Pass] Q2 — start-task routing text (`skills/1-hourly/start-task/SKILL.md:186-194`) matches the real machinery. Docs surface: `utils/ci-route.sh:292` (`*.md|*.txt|PROJECT/*|docs/*|relay-system/*|decisions/*|.pdda-*|.xyz-launch-artifact|TESTS-RESULTS/*`) with route=docs → the hook runs `"$REPO/utils/pdda/pdda.sh" run` (`githooks/pre-push:218-223`). Tiered/full retention: any unclaimed test change stays on the full gate (`utils/ci-route.sh:454`), unmapped non-doc paths fail closed to tier 3 (`:456`), DB paths map to the releases subsystem (`releases.sql|releases.db` at `:39`), rename/delete sides are seen because the hook diffs `--no-renames` (`githooks/pre-push:213`) and a deleted test forces full (`utils/ci-route.sh:403-406`). The retained "EXACTLY ONCE … only when the route requires it" (`:193`) is consistent with the docs carve-out; no internal contradiction. The skill's docs description (`*.md`/`*.txt`) is narrower than the classifier's full docs list — conservative, so misapplication errs toward the heavier gate, not the lighter one.
- [Pass] Q3 — rename complete for discovery, install, catalog, and test. `install.sh:16` `SKILL_NAME="where-are-we-at"`; frontmatter `skills/2-daily/where-are-we-at/SKILL.md:2` `name: where-are-we-at`; heading and new trigger (`:12`, `:50-51`); catalog row `ARCHITECTURE.md:85`; all test assertions updated including installer sandbox link names (`test/gh798-status-skill.sh:6,20,50,64-75`). Probes: `grep -rn "2-daily/status" --include="*.md" --include="*.sh" .` (rc=0) matches only dated 2026-09-24 relay transcripts and the CHANGELOG history line — immutable records, correct to keep; `grep -rn "\[status\](" --include="*.md" .` → rc=1 (no live catalog link). Catalog counts re-derived: `awk '/### \`1-hourly\`/,/### \`2-daily\`/' ARCHITECTURE.md | grep -c "^| \["` → 15; same for 2-daily → 16 — matching headings `ARCHITECTURE.md:44,66` and the test's `(16)` assertion (`test/gh798-status-skill.sh:51`); the other counting suite accepts 15|16 (`test/gh778-review-code-skill.sh:43`). No live old-name reference found that would break use.
- [Pass] Q4 — draft status is supported by the evidence on record. The only committed gate receipt is `TESTS-RESULTS/2026-09-25+GH-825/provenance.jsonl:1` (`"commit":"9b3a780d…","rc":0,"suites_recorded":421`, limitation: hosted macOS run required), which predates this head. The head's own diff contains `test/gh798-status-skill.sh` (unclaimed test → tier 3 per `utils/ci-route.sh:454`) and the installer script rename (unmapped non-doc → tier 3 per `:456`), so the operator's Markdown/text gate cannot qualify `f0e68399`. Exact remaining check: one classified full qualifying gate on head `f0e683992560` in a disposable full clone with a fresh provenance receipt, then the hosted checks on the pushed commit. No new framework or speculative tests are needed — the existing gh798 suite already covers the rename.
- [Pass] Q5 — 13-file diff is surgical and coherent: skill + catalog row + changelog (GH-825), plan doc, provenance receipt, two relay receipts (repo convention under dated `relay-system/`), ledger pair `releases.sql`/`releases.db` (generation 1184→1185 adding only the GH-825 roadmap row `releases.sql:751`, its op_receipts and work_events), and the two follow-ups (start-task hunk; rename triple of SKILL.md/install.sh/test). The handsfree catalog row sits in correct alphabetical position (`ARCHITECTURE.md:54`, between five and ponytail) and the 1-hourly count bump 14→15 matches the derived row count above. No unintentional change found in any touched file.
- [Nit] `skills/1-hourly/start-task/SKILL.md:193` is one ~130-char unwrapped line inside an otherwise hard-wrapped step; rewrap to the surrounding column width. Cosmetic only.
- [Nit] Pre-existing, untouched by this PR: `skills/2-daily/where-are-we-at/SKILL.md:125-127` use LaTeX math (`$\le 10$m`) that renders literally in GitHub Markdown. Optional cleanup, out of this PR's scope.
- [Unverified — needs clone run] No validate.sh, test scripts, pytest, executable fixtures, or git commands were run this turn per relay policy. Not attested here: the gh798 suite passing at this head, `releases.db` binary consistency with `releases.sql`, and the full qualifying gate on `f0e68399` — all belong to the harness gate / disposable full clone.
- [Unverified — network not attempted] Live PR #827 / issue #825 state was not queried; review is against the seeded patch at head `f0e683992560` vs base `31a42867` and the local plan/receipts, per the packet.

Relay closed (Approved), no further review turn needed. Producer (codex) owns the remaining qualifying-gate run on the head commit, the hosted-CI check, and undrafting PR #827.


### Attestation · relay-drive — 2026-09-25T21:00:46Z
task: RELAY-gh825-pr827-fable-high
reviewer: claude
status: Approved
reviewed-head: 7a5ee1f84d507250959ab9466ad40bdea5bb2042
added-range: 8098+7427
added-sha256: 9af6cd05dfc8c1cf69a9339a01eaf38bda159cf086240969c9b895ebafbfd046
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
