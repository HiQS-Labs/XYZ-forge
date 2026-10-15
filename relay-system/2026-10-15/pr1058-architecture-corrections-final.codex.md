# RELAY · PR1058 corrected architecture and historical export final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
-->

NEXT: Reviewer
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(pr1058-architecture-corrections-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: ARCHITECTURE.md, ARCHITECTURE/ledger-diagram.json and .html, GH1052 inbox intake, redacted historical HiQS relay export, CHANGELOG, ledger refresh and TESTS-RESULTS/2026-10-15+PR-1058-review-corrections/.
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-15
- Definition of Done: architecture prose/spec/HTML match current emitters and executing relay/attestation ownership; GH1052 remains parked intake; historical export and missing catalog evidence are honestly bounded; no runtime or deployment changes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log




### Producer · Round 1

Noel granted exclusive ownership takeover of PR1058. This reviews the Forge architecture corrections, not a restart of historical HiQS deployment QA2/2. Read full named touched artifacts and relevant existing runtime emitters: utils/py/releases_app.py, utils/py/wave_reconcile.py and utils/releases-merge-resolve.sh. Check switch semantics, adopted-view presence/delete behavior, diagram JSON/generated HTML fidelity and truthful historical attestation/catalog-evidence limits. Do not demand an installation/catalog apply: it is outside scope; missing receipt is explicitly unverified. Intake GH1052 must remain OPEN/inbox/parked; runtime and source bytes beyond docs/ledger intake are unchanged. Canonical B1 adopted development e09556a5 via existing writer; see retained resolution and focused56/56 evidence. A routine LEADERBOARD generation update was replaced with exact incoming bytes, per task-branch policy.

Read-only review; only this thread writable. No git command, test/validate/pytest, executable fixture, runtime mutation, installation or network operation. Narrow nonmutating file/byte comparisons permitted with bytecode disabled. New CI tests/cases require explicit Noel approval and none is given. Review material actual problems with cited observed input, scope and falsifier, not speculative scope expansion. Append at absolute EOF `### Reviewer (codex) · Round 1`, VERDICT: PASS or FAIL, Basis and swept file: yes/no. On PASS set STATUS Approved, NEXT — and tick done RELAY-PR1058-ARCH-FINAL-20261015. Normal publication and hosted qualifications remain producer obligations. Handing off to Reviewer.

### Reviewer (codex) · Round 1

VERDICT: FAIL
Basis: The requested projection and historical-evidence corrections agree with the seeded source, but the whole ARCHITECTURE.md sweep found two material, pre-existing documentation inaccuracies. Fix those descriptions only; no runtime change, deployment, catalog operation, new test or gate is requested. This is an Easy documentation correction. Publication and hosted qualification remain Producer obligations.
swept file: no

Scope/limits: Read all of ARCHITECTURE.md, the ledger spec, generated HTML renderer/template and embedded spec, GH1052 intake, historical deployment export and the five correction-evidence files. Read the relevant existing writer/reconciler/resolver branches. Read the current CHANGELOG correction and scanned its entire 1,061,410-byte history programmatically; did not reread/requalify every archival entry, so the aggregate sweep declaration is conservatively **no**. The nearest graph is a different checkout, generation 2026-09-01T15:54:30Z; coverage reported changed/missing/excluded paths, so material findings use seeded source rather than stale graph assertions. No Git, suite, fixture, network operation or source/artifact mutation was performed.

- [Should] S1 — Describe the executing Python lane, and distinguish its Bash fallback. `ARCHITECTURE.md:173` says “The architecture is shell processes spawning shell processes”; `:217` and `:270` describe the shared sleep/kill watchdog as the path used by every shim; `:229` gives the Codex default without its noninteractive approval setting. The entry shim actually defaults through `exec python3` (`relay-automation/relay-drive.sh:9–18`), and the executing Codex lane builds `-s workspace-write -c approval_policy=never` (`utils/py/codex-turn.py:14–17`) and uses `subprocess.run(... timeout=turn_timeout ...)` (`:110–112`). The document's “current code” assertion (`ARCHITECTURE.md:233`) therefore points maintainers at the wrong runtime and gives an incomplete headless command.
  Observed input: default/unset `XYZ_PYTHON`, and unset `CODEX_FLAGS`; the source expressions above select Python and include `approval_policy=never`, contrary to the current narrative/table.
  Affected scope: this document's runtime ownership, watchdog and Codex default-command descriptions; frozen Bash code stays untouched.
  Falsifier: an entry shim that defaults to its inline Bash body, plus an executing Codex default without the approval setting, would invalidate the finding. The seeded source shows the opposite.
  Concrete fix: name the Python implementations and default routing, identify `XYZ_PYTHON=0` as the historical Bash fallback, qualify Bash-only watchdog details, and show the actual Codex default including the approval setting. Preserve the existing shared containment owner distinction. Source-only command `sed -n '1,25p' relay-automation/relay-drive.sh` and `sed -n '10,20p;98,128p' utils/py/codex-turn.py` (run through the numbered equivalents), exit 0; decisive spans: `if [[ "${XYZ_PYTHON-1}" == "1" ]]`, `exec python3`, and `"-s workspace-write -c approval_policy=never"`. No CLI was launched.

- [Should] S2 — Include driver attestation in the terminal/approval contract. `ARCHITECTURE.md:189–198` presents Approved/Closed as the terminal signal, and the example at `:387` says token done + terminal STATUS → stop, without the required observed reviewer turn and attestation. `utils/py/relay_drive.py:778–788` explicitly refuses a terminal/done state if `attested` is empty; `:693–764` also rejects builder/failed turns, rewritten/empty review text and a token that is not done. Omitting this condition misdescribes the approval boundary and makes an already-Approved historical file look sufficient for a fresh successful run.
  Observed input: the concrete source branch `terminal_status(s)` with no live actor and empty `attested` at `utils/py/relay_drive.py:778–783`; it calls `exit_unattested`, rather than the successful stop described in the example.
  Affected scope: the terminal-state explanation and end-to-end example in ARCHITECTURE.md; approval/runtime behavior remains unchanged.
  Falsifier: a current driver branch that accepts terminal STATUS + done without in-process reviewer attestation would invalidate this finding. The seeded branch explicitly escalates instead.
  Concrete fix: state that terminal text and a done token are necessary but insufficient; the driver must observe and attest a successful reviewer turn, tying the review bytes to the reviewed revision/artifact. Explain that pre-existing terminal text is rejected. Command `nl -ba utils/py/relay_drive.py | sed -n '693,790p'`, exit 0; decisive output: `if not attested: exit_unattested(...)`, and the helper's `exit_escalate("unattested-terminal")` (`:766–769`). This is source evidence, not an executed relay scenario.

- [Pass] The projection correction matches the existing emitters: switch before presence for ordinary writes (`utils/py/releases_app.py:1344–1384`) and hosted refresh (`utils/py/wave_reconcile.py:1810–1830`); explicit merge regeneration and merge-parent deletion handling independently of that setting (`utils/releases-merge-resolve.sh:161–223`). `ARCHITECTURE.md:418–430`, JSON nodes at `ARCHITECTURE/ledger-diagram.json:30–42`, and its switch-bypassing merge edge (`:66`) reflect that distinction. No fix requested.
- [Pass] Spec/HTML fidelity and nonempty graph measured. Command (with `PYTHONDONTWRITEBYTECODE=1` and scratch TMPDIR): `python3 -c 'import json,re;from pathlib import Path;s=json.loads(Path("ARCHITECTURE/ledger-diagram.json").read_text());h=Path("ARCHITECTURE/ledger-diagram.html").read_text();e=json.JSONDecoder().raw_decode(h[re.search(r"var spec =\s*",h).end():])[0];print("nodes",len(s["nodes"]),"edges",len(s["edges"]),"equal",s==e);s["nodes"][0]["label"]="RED CONTROL";print("mutated_equal",s==e)'`, exit 0: `nodes 27 edges 33 equal True`, `mutated_equal False`. An additional read-only in-memory reconstruction using the canonical template, renderer and builder substitution rules returned `HTML full canonical-template rendering byte-equivalent True`; all edge endpoints, groups and node IDs were valid. Relevant embedded data starts at `ARCHITECTURE/ledger-diagram.html:1000`. No artifact was regenerated on disk.
- [Pass] GH1052 remains local intake: `PROJECT/1-INBOX/GH-1052-RECON-VENDOR-CONTRACTS.md:3` says Proposed/not active and its nine checkboxes remain unchecked. Command `python3 -c 'import sqlite3;c=sqlite3.connect("file:releases.db?mode=ro&immutable=1",uri=True);print(c.execute("select gh_number,section,status_marker,doc_path from roadmap_items where gh_number=1052").fetchall())'`, exit 0: `[(1052, 'Queue / parked intake', '🆕', 'PROJECT/1-INBOX/GH-1052-RECON-VENDOR-CONTRACTS.md')]`. Read-only queries also found the roadmap-add/update receipts and DB/SQL generation 1650. GitHub's live OPEN state was not queried in this no-network turn.
- [Pass] Historical export limits are explicit: `relay-system/2026-10-13/hiqs-skills-army-deploy-qa.md:3–7` ties the retained digest/range to the unmodified published original, not this redaction; `:164–177` says a separate catalog preview/apply receipt is unverified and performs no operation. The old rounds remain historical; no new deployment approval is requested. `CHANGELOG.md:15–28` and correction `SUMMARY.md:7` use the same bounded claim. No fix requested.
- [Unverified — needs clone run] Retained suite evidence reports 56/56 at `aae709a23442a296821d5da0a4edcb7644375dd4` (`TESTS-RESULTS/2026-10-15+PR-1058-review-corrections/provenance.jsonl:1`); the log contains red controls and the 56/0 total (`existing-swe-diagram.log:47–58`). This turn inspected those receipts but ran no suite and does not qualify the final candidate, preserved incoming LEADERBOARD bytes, live issue state, or original remote attestation blob independently. `SUMMARY.md:9` correctly leaves current-head/publication/hosted qualification pending.

Handing off to Producer (codex-producer) — correct or disposition S1/S2, retain the bounded evidence claims, then return the next round to Reviewer. Harness owns the file-scoped commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->


### Producer · Round 2

S1 Implemented — current Python dispatcher/rtl bridge ownership and explicit historical Bash fallback replace the stale shell-only default. Timeout descriptions distinguish Codex subprocess timeout, agy bounded process-group/idle loop and Claude shared Python helper. Codex default flags include the existing noninteractive approval setting and shared tick path; persistent log default corrected. Agy core default print-timeout is900s, not300s. Python source owners are linked in verified_against and agent sections; no executable behavior or permission changed.

S2 Implemented — terminal text plus done is necessary but insufficient; successful reviewer-role turn, immutable prior text and nonempty review-byte attestation from this driver run are required. End-to-end example rejects pre-existing unattested terminal state. Source assertions were cross-referenced at utils/py/relay_drive.py judge_terminal/exit_unattested and each Python dispatcher.

Earlier review turns remain unchanged. Please recheck the current whole changed document and bounded previous requested artifacts, with source-grounded material findings only. Literal swept file declaration can distinguish archival changelog history from current file owners; do not requalify unrelated historical work. Only this thread writable; no git/test/validate/fixtures/network. Append at EOF `### Reviewer (codex) · Round 2`, VERDICT/Basis/swept file. On PASS header Approved/NEXT —, tick done RELAY-PR1058-ARCH-FINAL-R2-20261015. Normal publication/exact-head checks remain pending. Handing off to Reviewer.
