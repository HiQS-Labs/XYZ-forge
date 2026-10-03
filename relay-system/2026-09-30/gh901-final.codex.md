# RELAY · GH-901 Codex task-sync final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-30.
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
6. **Commit only the relay file** (`relay(gh-901-codex-task-sync-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh901-review.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: producer
- Started: 2026-09-30

### Artifact — gh901-review.md
```
Review GH-901 Codex desktop extension ONLY (inherited PR #900 is the prerequisite).
Read PROJECT/2-WORKING/GH-901-CODEX-TASK-SYNC.md, skills/3-weekly/task-sync/SKILL.md, scripts/core.py, scripts/task_sync.py, scripts/adapters/codex.py under that skill, and TESTS-RESULTS/2026-09-30+GH-901/.
Local desktop envelope: one native heartbeat, read-only snapshot planner, native supported title/pin tools own writes. No app-store writes, extra scheduler, new test suites/gates, cloud support or enterprise machinery.
1. Is core/CLI reuse correct, old adapters unchanged except optional title-length knob?
2. Does snapshot validation fail closed for invalid/empty/stale/activity errors and preserve groups/pins? Inventory intentionally bounded to all pins plus 50 recent native chats.
3. Are native procedure preconditions, exclusion, verification, and no-blind-retry requirements sufficient in this local envelope? Native tools have no CAS; residual concurrent manual-edit race is documented.
4. Are timestamps derived from actual turn, never metadata updatedAt? Native observed read_thread returns numeric Unix seconds, not ISO text.
5. Are manual probes meaningful and commensurate? No new registered suite. Do NOT run validate.sh/test/*.sh/pytest here; gate will run separately in a disposable full clone. You may run nonmutating narrow Python probes under scratch.
State Blocker/Should only with observed input, affected scope, falsifier and exact source citation. Approve if no blocking defects. Do not edit artifact or commit; write only the relay review.
```
- Definition of Done: Native Codex snapshot planning reuses task-sync, preserves titles/pins/groups, refuses invalid input, and has meaningful recorded falsifiers; no blocking correctness defect in the extension.

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

VERDICT: PASS
Basis: Swept the complete embedded artifact, working document, skill procedure, core.py, task_sync.py, codex.py and manual-probe source/output/provenance. No blocking correctness defect or additional pre-existing defect found in these files within the native desktop envelope. Disposable-clone gate and native deployment remain pending.

- [Pass] Reuse: core.py:74 retains the default title cap; adapters/codex.py:103 uses max_length=None. CLI default is still “zcode,agy”; Codex preflight refuses unsupported writes before dispatch. Historical old-adapter identity against PR #900 was not diffed (git prohibited), so historical diff identity is not attested.
- [Pass] Validation/preservation: adapters/codex.py:30, :39, :59, :66, :96 reject stale/empty/ambiguous/pin-disagreement/missing-activity inputs. Lines 90-99 skip heartbeat, other hosts/kinds/custom groups and old actual activity. Line 104 stamps actual turn seconds.
- [Pass] Independent narrow probe command: PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 - (inline Python importing core/CodexAdapter, using TemporaryDirectory snapshots only). Input: fresh local chats row x with long title, updatedAt=now and activity=now-60; controls: activity={}, activity=now-90000; stable replan: proposed title and pinned section applied to synthetic snapshot. Exit 0. Decisive output: “positive: rename=1 pin=1 full wording retained”; “missing activity: refused: Codex actual turn activity missing/invalid for x”; “metadata recent / actual old: swept=0”; “stable replan: rename=0 pin=0”. Guards: adapters/codex.py:95-110.
- [Pass] Native procedure specifies refreshed title/section/activity preconditions, exclusion, title-then-pin sequencing, readback and no blind retry. Its explicit caveat is “Native tools have no compare-and-swap: the prechecks reduce, but cannot eliminate, a concurrent manual-edit race.” Sufficient for the stated local envelope, without promising CAS.
- [Pass] Recorded manual_probe.py contains invalid/stale/empty/activity controls and deleted-rename assertion control; manual-probe.json records 28 checks. Independent command hashlib.sha256(Path('TESTS-RESULTS/2026-09-30+GH-901/manual-probe.json').read_bytes()).hexdigest() returned efdaeaba837800f0cbb8423ec1ef6b0ef0af47f362431622a611206e852ea2df, exit 0, matching provenance.jsonl. Recorded executable was read, not run here.
- [Unverified — needs clone run] Full gate and live native smoke were not rerun. No validate.sh, test/*.sh, pytest or executable fixtures ran. Graph XYZ-forge generation 2026-09-01T15:54:30Z has no task-sync symbols and missing freshness for the code paths; exact complete seeded source reads supplied the evidence.

Relay closed (Approved), no further review turn needed. Handing token to producer for separate gate and delivery.

### Producer · Round 2

VERDICT: READY FOR REVIEW
Round 1's independent PASS is retained. The supervisor refused terminal approval
because the token was released to producer (close-mismatch); no driver-attested
approval is claimed for it. Recheck the current integrated extension, then on
approval use the absolute env-pinned tick `done gh901-final --agent codex
--relay-file relay-system/2026-09-30/gh901-final.codex.md` and **do not release it**.
The shim owns the commit; never run git. Current development was merged with no
source changes to task-sync; canonical ledger resolver retained both branches'
rows and check is clean. Native smoke succeeded: 5 renamed, 6 newly pinned, all
readbacks verified, aggregate provenance committed. ARCHITECTURE now names Codex.  [Unverified — no citation]
Existing legacy ZCode automation found active. Native installer will pause it
through app UI before enabling one replacement heartbeat that invokes the
existing ZCode adapter and native Codex procedure; no new Antigravity enablement.
Gate remains for the separate disposable full clone. No further code changes.

### Reviewer · Round 2
swept file: yes

VERDICT: PASS
Basis: Read the complete embedded artifact, GH-901 working document, task-sync skill, core.py, task_sync.py, codex.py, and all three GH-901 evidence files. No blocking correctness defect or additional pre-existing defect found in the reviewed extension surfaces within the stated local desktop envelope. Approval is review completion; the disposable-clone gate and scheduler consolidation remain separate delivery obligations.

- [Pass] Core reuse and read-only boundary: skills/3-weekly/task-sync/scripts/core.py:74 keeps the default cap with optional max_length; adapters/codex.py:103 disables truncation for native titles. task_sync.py preflight states “Codex plans only: apply titles/pins via native tools”; it runs before dispatch. Historical identity of old adapters against PR #900 is not attested because git is prohibited.
- [Pass] Validation, actual activity and preservation: skills/3-weekly/task-sync/scripts/adapters/codex.py:30 rejects stale captures; :39 rejects empty inventory; :66 rejects pin/sidebar disagreement; :90 excludes heartbeat, other hosts/kinds and custom sections; :96 refuses missing/invalid activity; :104 stamps actual turn seconds. Independent narrow probe command: export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - (inline Python importing core/CodexAdapter, synthetic TemporaryDirectory JSON only). Input x: local Codex chats row, updatedAt=now, activity=now-60, title='Investigate '+'word '*40. Controls: activity={}, captured_at=now-301, threads=[], section='pinned' with no pinned inventory, activity=now-90000; stable replan uses proposed title and pin. Exit 0. Decisive output: “positive: rename=1 pin=1 full wording retained”; “missing activity: refused: Codex actual turn activity missing/invalid for x”; “stale: refused: Codex snapshot stale or invalid (freshness limit 300s)”; “empty: refused: Codex empty inventory refused”; “pin mismatch: refused: Codex pinned inventory disagrees with sidebar sections”; “metadata recent / actual old: swept=0”; “stable replan: rename=0 pin=0”.
- [Pass] Native procedure requires refreshed observed identity/title/section/activity, exclusion, recent-window checks, readback, and title-then-pin sequencing. Exact skill spans: “If both apply, the pin precheck expects the newly verified title instead of the original”; “On tool failure stop; read native state before retrying”; “Native tools have no compare-and-swap”. This explicitly retains the residual concurrent manual-edit race rather than claiming atomicity. Single-scheduler migration requires “retire/disable the previous job before enabling the replacement”.
- [Pass] Recorded manual evidence is meaningful: TESTS-RESULTS/2026-09-30+GH-901/manual_probe.py includes invalid/stale/empty/activity controls and the deleted-rename red assertion; manual-probe.json reports “passed”: 28. The same independent inline probe computed SHA256 efdaeaba837800f0cbb8423ec1ef6b0ef0af47f362431622a611206e852ea2df (exit 0), matching provenance.jsonl. The native smoke provenance reports 5 renames, 6 pins and 6 readbacks; this is coordinator-recorded aggregate evidence, not an independently rerun native smoke.
- [Unverified — needs clone run] Full gate not run here; no validate.sh, test/*.sh, pytest or executable fixture was invoked. Native deployment/consolidation not performed by this reviewer. Graph project XYZ-forge generation 2026-09-01T15:54:30Z returned zero task-sync symbols and missing freshness for all four queried code/evidence paths; complete exact seeded-source reads supplied fallback evidence. No graph completeness claim.

Relay closed (Approved), no further review turn needed. Producer owns the separate disposable-clone gate and delivery; closing the token with done, without release.


### Attestation · relay-drive — 2026-09-30T18:52:59Z
task: gh901-final
reviewer: codex
status: Approved
reviewed-head: 0b18f924a0645c66dc93f20dfe55e0272898cd16
added-range: 10960+3871
added-sha256: 78d6ea56667a6782d9027723031519a19a10a8d512de200c73df46897eb409aa
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
