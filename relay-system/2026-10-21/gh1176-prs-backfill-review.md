# RELAY · QA: PR #1176 prs-backfill — reviewed PRS rating backfill (GH-1175)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-21.
-->

NEXT: Producer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh1176-prs-backfill-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/prs_backfill.py`
- Scope: PR #1176 (branch feat/gh1175-prs-backfill, head 834ca8dcc) — read these files in
  full in this worktree (they ARE the PR; everything else in the repo is pre-existing):
  - `utils/py/prs_backfill.py` (new, 836 lines — the whole implementation)
  - `skills/2-daily/prs-backfill/SKILL.md`, `prs-backfill.sh`, `install.sh` (new)
  - `CHANGELOG.md` top entry (2026-10-21, GH-1175) and the one `ARCHITECTURE.md` row
  - Context only, do not grade: `utils/py/releases_app.py:3694-3768` (`cmd_roadmap_rate`, the ONE
    writer this tool shells out to) and `skills/1-hourly/start-task/SKILL.md:335-380` (the rating policy).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-21
- Operational envelope: a local, operator-attended CLI run from one checkout (macOS, python3 stdlib,
  `gh` on PATH). Single-instance per repo. No service, no multi-tenant, no cross-host. The ledger
  (`releases.db`) is written ONLY by `releases roadmap rate`; this tool never opens it read-write.
  Repo rule GH-831 (`AGENTS.md`): **no new tests, no new gate machinery** — do not ask for a test
  file; a new test in the diff would itself be a finding.
- Definition of Done (grade against these, cite `file:line`):
  1. **No second writer.** Every ledger mutation goes through `run_rate()` → `releases roadmap rate`
     without `--force` or `--ovr`; `open_ledger_ro()` is the only other DB access and is `mode=ro`.
     Is there any path where this tool writes `releases.db` directly or re-scores an existing rating?
  2. **Approval binding.** `apply` refuses unless `--approve` is a ≥12-hex prefix of
     `sha256(plan.items)` and `plan.json` is untampered. Can a changed proposal reach the ledger under
     an old hash? Can `items` ordering or JSON canonicalisation make two different plans share a hash?
  3. **Freshness before write.** Before each write `apply` re-fetches the issue, holds on
     `closed-since-scan` / `changed-since-scan` (content hash of title/body/labels/comments, not
     `updatedAt`), re-reads the row (ambiguous / already-rated / legacy held). Is there a TOCTOU gap
     that matters at the stated envelope (one operator, one checkout)? Grade commensurately.
  4. **Honest exit and receipts.** A failed write or read-back mismatch → `write-failed` receipt, stop,
     exit 3; a judgment hold (`held`) suppresses re-selection on unchanged `updatedAt`, a `write-failed`
     does not; `--include-held` lifts the filter for an attended re-rate. `--post-rationale` comments
     only after a verified read-back. Trace `cmd_apply` and `cmd_scan` and confirm or refute each.
  5. **E0 blindness.** Calibration packets must carry no ledger score: `build_packet` never includes
     `rating_*`; `strip_rating_lines` withholds the capture doc's `rating:` frontmatter;
     `select_calibration` skips placeholder rows (all axes ≤5, or exactly 50/50/50/50). Any remaining
     leak path (body text, comments, labels) you can point to?
  6. **Policy enforcement in `check_proposal`.** appeal == 50 unless `--appeal-map`; all four axes int
     1–100 (bool rejected); rationale complete and ≤1200 chars; confidence high|medium; rater identity;
     reviewer present, independent (agent+model differ) and `agree` unless `--no-review`. Anything
     the start-task policy requires that this misses, or anything it enforces that the policy does not?
  7. **Locks and kill switch.** `Lock` uses `a+` + flock + truncate-after-acquire; `PRS_BACKFILL_DISABLE=1`
     covers scan/validate/apply/calibrate, not `status`. Correct at this envelope?
  8. **Commensurate complexity.** 836 lines for scan/validate/apply/calibrate/status. Name anything
     that is speculative, duplicated inside the file, or duplicates an existing helper in
     `utils/py/` (you may grep). Do NOT propose new subsystems, schemas, or tests.
  9. **Docs truthfulness.** Does `SKILL.md` describe exit codes, holds, receipts and flags exactly as the
     code behaves? Quote any sentence that is false.
- Non-goals: the hosted/foreman control plane in #1175; registration of unregistered issues (#1022);
  the placeholder-rating ledger defect (#1177); scheduling (#1168). Do not grade those.
- Output: one Reviewer block with `swept file: yes|no`, graded findings each with `file:line` and a
  concrete fix, every `[Blocker]`/`[Should]` behaviour change with `Observed input:` / `Affected scope:` /
  `Falsifier:`, then **VERDICT** (PASS / FAIL / PARKED) and **Basis**. You may run read-only probes
  (`python3 utils/py/prs_backfill.py --help`, `python3 -c ...` against the file) with output under
  `$TMPDIR`; do not run `validate.sh` or `test/*.sh`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

**Block — scoped fixes required.**

swept file: yes

Read all 836 implementation lines, all three skill files, the CHANGELOG entry and ARCHITECTURE row; traced the canonical writer and rating policy as context. These implementation/skill files are new; no separate pre-existing defect was found in the reviewed touched-file scope. Graph tools were unavailable, so source reads and bounded searches supplied the evidence. Review uses the stated attended, single-checkout envelope; it does not require service-grade concurrency or a new subsystem.

- **[Should] F1 — E0 still exposes the answer in capture-doc prose.** `utils/py/prs_backfill.py:313`, `:340`, `:348` only replace `rating:` lines; `:332` passes other score text straight to the rater. Actual seeded rows GH-589 and GH-579 are classified `rated`, are not placeholders, and their packets expose exactly their ledger scores. Examples: `PROJECT/1-INBOX/GH-589-XYZ-MINI-SYNC.md:44` contains `` `rated 55/25/50/40` ``; `PROJECT/1-INBOX/GH-579-HIQS-CONSUMER.md:66` contains `rated 70/55/50/25`. This contradicts SKILL.md:112–113, “The packet never contains them.”
  Observed input: the two real rows and capture-doc excerpts above, passed to `build_packet(..., mode="calibrate")`.
  Affected scope: explicit prior PRS score disclosures in capture-doc prose, in addition to the already handled frontmatter; no claim that arbitrary numbers or unrelated labels need filtering.
  Falsifier: both rows' calibration packets must withhold those score tokens while preserving useful consequence prose; a doc with only `rating:` frontmatter must remain withheld too.
  Root cause: filtering recognizes one serialization of the answer; Fix site: packet evidence sanitization; Why not upstream/downstream: the canonical docs may retain their ratings, but the blind rater must not receive them. Redact the observed prose tokens as well, or omit such scored excerpts from E0, and align the blindness claim with the actual packet boundary.
  Probe command (run with `PYTHONDONTWRITEBYTECODE=1`, output redirected to `$TMPDIR/packet-probe.txt`; exit **0**):
  ```python
  import importlib.util, re
  s=importlib.util.spec_from_file_location('pb','utils/py/prs_backfill.py')
  p=importlib.util.module_from_spec(s); s.loader.exec_module(p)
  c=p.open_ledger_ro('.'); rows=p.ledger_rows(c); c.close()
  for n in (589,579):
      r=rows[n][0]
      live={'number':n,'title':r['title'],'body':'','comments':[],'labels':[]}
      pk=p.build_packet('HiQS-Labs/XYZ-forge','.',r,live,'calibrate')
      print(n,p.classify(live,[r],{}),p.is_placeholder_rating(r),
            re.findall(r'rated \d+/\d+/\d+/\d+',pk['doc_excerpt'] or ''))
  ```
  Executed as `python3 - <<'PY' > "$TMPDIR/packet-probe.txt" 2>&1` (the recorded run also printed the four ledger scores and doc paths). Decisive output: GH-589 `classification: "rated", placeholder: false, scores: [55,25,50,40]`, excerpt `` `rated 55/25/50/40` ``; GH-579 `classification: "rated", placeholder: false, scores: [70,55,50,25]`, excerpt `assessment: rated 70/55/50/25`.

- **[Should] F2 — subprocess timeouts bypass the promised receipts.** `utils/py/prs_backfill.py:587` raises on writer timeout, and `cmd_apply` calls it outside any handler at `:666`, so the `write-failed` append at `:688` and exit-3 return at `:702` are unreachable. The optional comment call has the same gap at `:600`: it occurs at `:685` after verified ledger mutation but before the `applied` receipt. A timeout there loses the durable success receipt despite an already verified rating. SKILL.md:145 says, “The first failed write or read-back stops the run with exit `3` and a `write-failed` receipt”; that does not cover the actual timeout path.
  Observed input: `subprocess.TimeoutExpired('roadmap rate',120)` at the writer boundary, and `subprocess.TimeoutExpired('gh issue comment',120)` at the optional comment boundary, using the valid GH-589 item below. Both escape their actual wrappers.
  Affected scope: these two subprocess timeout paths, not arbitrary malformed ledger data or speculative later failures.
  Falsifier: an injected writer timeout must leave a `write-failed` receipt and stop with exit 3; after successful write/read-back, an injected comment timeout must preserve an `applied` receipt with the comment failure reported. Ordinary rc=0 and rc!=0 paths must retain their documented behavior.
  Root cause: receipt creation follows fallible external calls without handling their timeout result; Fix site: the apply orchestration and its subprocess wrappers; Why not upstream/downstream: external calls can time out legitimately, and status cannot reconstruct the missing evidence. Convert writer timeout into the existing failure path; handle comment timeout separately so it cannot erase a verified application. No automatic retry or new receipt subsystem is needed.
  Probe command: `python3 - <<'PY' > "$TMPDIR/timeout-probe.txt" 2>&1` using:
  ```python
  import importlib.util, subprocess
  from unittest.mock import patch
  s=importlib.util.spec_from_file_location('pb','utils/py/prs_backfill.py')
  p=importlib.util.module_from_spec(s); s.loader.exec_module(p)
  it={'issue':589,'rated':'55/25/50/40',
      'rationale':{'consequence':'feature','recurrence':'unknown trend','uncertainty':'estimate'},
      'rater':{'agent':'codex','model':'m'},'review':{'agent':'claude','model':'n'}}
  for label,fn,args in [('writer',p.run_rate,('/unused',589,it['rated'],False)),
                        ('comment',p.post_rationale,('unused/repo',it,'a'*64))]:
      with patch.object(p.subprocess,'run',side_effect=subprocess.TimeoutExpired(label,120)):
          try: print(label,fn(*args))
          except Exception as e: print(label,'uncaught',type(e).__name__)
  ```
  Executed in two equivalent narrow wrapper probes (`function-probes.txt` and `comment-probe.txt`), both exit **0** because the probe catches the exception for reporting. Decisive output: `timeout_result: uncaught TimeoutExpired Command 'roadmap rate' timed out after 120 seconds` and `comment_result: uncaught TimeoutExpired Command 'gh issue comment' timed out after 120 seconds`. The subprocess function was replaced only in memory; no writer/comment process ran. **[Unverified — needs clone run]** End-to-end process exit and persisted-receipt behavior after the fix require the disposable-clone gate/manual run; the current missing-handler path is established by source trace and these wrapper observations.

- **[Should] F3 — a freshness hold suppresses the newly changed evidence.** `utils/py/prs_backfill.py:641` detects changed content, but `:663` records the LIVE `updatedAt` in the hold while retaining the OLD content hash in `base` (`:629`). `cmd_scan` then treats every `held` receipt as a judgment hold (`:394`, `:423`), suppressing that issue at its new timestamp. Consequently the version that invalidated the proposal is never selected for fresh judgment until another issue edit or a manual `--include-held`.
  Observed input: issue 589 scanned at `2026-10-21T10:00:00Z`, edited to `10:01:00Z` before apply; receipt `{type:held,stage:apply,reason:changed-since-scan,issue:589,issue_updated_at:2026-10-21T10:01:00Z,content_hash:old-content}`; next inventory still at `10:01:00Z` and the ledger still unrated.
  Affected scope: `changed-since-scan` holds whose receipt timestamp is the newer evidence timestamp; genuine judgment holds on unchanged evidence must still suppress re-selection.
  Falsifier: the next default scan should select this changed version without `--include-held`; a low-confidence hold actually judged at `10:01:00Z` should remain suppressed at that timestamp.
  Root cause: an invalidated old judgment is labeled as a judgment about the new issue version; Fix site: freshness-hold receipt timestamp or scan's reason-specific suppression; Why not upstream/downstream: issue edits are legitimate, and requiring another edit to wake selection loses work. Keep the original scan timestamp for this hold, or exclude this freshness reason from judgment suppression.
  Probe command: `python3 - <<'PY' > "$TMPDIR/resume-probe.txt" 2>&1` using:
  ```python
  import ast, importlib.util
  s=importlib.util.spec_from_file_location('pb','utils/py/prs_backfill.py')
  p=importlib.util.module_from_spec(s); s.loader.exec_module(p)
  t=ast.parse(open('utils/py/prs_backfill.py').read())
  f=next(x for x in t.body if isinstance(x,ast.FunctionDef) and x.name=='cmd_scan')
  expr=next(x.value for x in ast.walk(f) if isinstance(x,ast.Assign)
      and isinstance(x.value,ast.ListComp)
      and any(isinstance(z,ast.Name) and z.id=='held' for z in ast.walk(x.value)))
  rec={'type':'held','stage':'apply','reason':'changed-since-scan','issue':589,
       'issue_updated_at':'2026-10-21T10:01:00Z','content_hash':'old-content'}
  ctx={'cands':[589],'held':p.latest_by_issue([rec],{'held'}),
       'updated':{589:'2026-10-21T10:01:00Z'}}
  print(eval(compile(ast.Expression(expr),'<cmd_scan selection>','eval'),ctx))
  ctx['updated'][589]='2026-10-21T10:02:00Z'
  print(eval(compile(ast.Expression(expr),'<cmd_scan selection>','eval'),ctx))
  ```
  Exit **0**. Decisive output from the actual extracted selection expression: `changed-since-scan next candidates: []`; later-edit control: `later-edit control candidates: [589]`. This was an in-memory predicate probe, not a scan or fixture execution.

- **[Should] F4 — the normal skill procedure leaves the required rationale outside the canonical task record.** SKILL.md:138–139 presents apply without `--post-rationale`; `:150–152` explicitly makes publication optional. The script defaults that flag off (`utils/py/prs_backfill.py:818`), so the only automatic rationale persistence is the ignored local receipt (`:627`, `:688`). The canonical rating policy (context `skills/1-hourly/start-task/SKILL.md`, “Keep a short dated rationale with each task's canonical plan/issue”) still governs, and SKILL.md:28 says that policy wins. This is a procedure/policy gap, not a request for unsolicited comments.
  Observed input: the documented normal command `apply --run <run_id> --approve <sha12>`, with a valid accepted proposal carrying its rationale; no procedure step attaches that rationale to the task's canonical issue or plan.
  Affected scope: normal skill completion where rationale exists only in local `.tick/prs-backfill/`; already recorded canonical rationales need no duplicate publication.
  Falsifier: following the documented ordinary procedure must leave a short dated rationale on the canonical task record as well as the local receipt; the operator may choose the approved comment path or the existing plan record.
  Root cause: the procedure makes its sole canonical-record step optional without supplying an alternative; Fix site: SKILL.md procedure; Why not upstream/downstream: the policy already exists and the writer deliberately stores scores only. Add an explicit required procedure step to record/read back the dated rationale on the canonical plan/issue, using the optional comment flag only when authorized. No new schema or writer is needed. This finding is source/procedure evidence; no GitHub comment or ledger mutation was attempted.

- **[Pass] Core design is appropriately bounded.** DB access is read-only at `utils/py/prs_backfill.py:218`; the sole rating invocation at `:583–586` has neither `--force` nor `--ovr`, and already-rated rows are skipped at `:651–652`. Hashing canonicalizes object keys while preserving array order (`:73–78`); validate sorts items (`:560`) and apply checks both the stored digest and >=12-character approval prefix (`:614–619`). Narrow function controls returned `canonical_key_order_same: True`, `changed_score_same: False`, `appeal-must-be-50`, `invalid-pri` for boolean True, and `low-confidence` (probe exit 0). These are function/source checks, not an end-to-end write attestation.
- **[Pass] Lock/kill-switch and ordinary policy checks match the stated envelope.** `utils/py/prs_backfill.py:153–160` opens `a+`, acquires flock, then truncates; `:170–172`, `:379`, `:528`, `:606`, `:708` cover all mutating commands while status at `:764` remains readable. Proposal checks at `:494–523` enforce axis range/bool rejection, appeal map, rationale bound, confidence and independent agent/model pair with `agree`. Placeholder exclusion is explicit at `:355–366`. No compelling extra subsystem or speculative abstraction was identified: `harness_paths.github_slug_from_origin` is already reused at `:127`, and the canonical writer owns a different lock/transaction contract. The shell locators and ARCHITECTURE row add no separate blocking finding.

**VERDICT: FAIL**

**Basis:** F1–F4 prevent approval against DoD 4–6 and the canonical rationale policy. Probes were narrow/read-only or in-memory; all captured output stayed under `.relay-scratch/tmp`, and the decisive evidence is quoted above because scratch is discarded. No source/artifact edit, direct git command, full gate, `test/*.sh`, pytest, ledger mutation or public comment was run. The harness still owes its disposable-full-clone verification against the final producer revision. No new test or gate is requested.

Handing off to Producer claude-a — disposition F1–F4 and open round 2 after the scoped fixes; go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
