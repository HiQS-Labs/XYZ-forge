# RELAY · GH-1279 Stage A plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
-->

NEXT: Reviewer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh1279-stagea-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1279-READ-ONLY-PLANNING-SOAK.md`, section "Stage A plan — Codex decision adapter (this PR)". Read the whole doc plus the issue text it mirrors, and these sources: `utils/py/harness.py` (`AdapterResult`, `rules_decide`, `_adapter`, `_validate`, `_settle`, `run_tick`, `init_instance`, `init_from_prs`, `factory_parser`), `utils/py/proc_group.py` (`run_bounded`), `utils/py/factory_primitive/prompts/evaluator.v1.md`, `utils/py/factory_primitive/schemas/decision.schema.json`, `PROJECT/2-WORKING/GH-1248-OUTER-LOOP-PRIMITIVE.md`, `AGENTS.md` (No new tests, GH-831).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-30
- Definition of Done: the plan's "Acceptance (Stage A)" list is achievable, falsifiable and grounded in the real code paths; nothing in the issue's six Codex-arm entry gates is missing from the plan or silently dropped.

**Operational envelope.** Local single-operator harness on one Mac; an 8-hour read-only experiment behind an existing, validated loop. Grade against the stated requirements and commensurate complexity. Do NOT ask for multi-tenant threat models, retries, new test suites or registry entries (GH-831 forbids them), or machinery beyond one adapter function plus three init flags. Challenge any bloat in the plan itself.

**Questions** (cite file:line):
1. Is each claim in the Recon section true of the code? In particular: does `run_tick` reserve, call `_adapter`, `_settle`, persist raw to `telemetry/transcripts`, route `decision is None` to safe idle, and pause at `spent >= daily_cap` exactly as stated?
2. Does the design extend the existing seam (`_adapter`, `AdapterResult`, config) without a second writer or loop? Is `run_bounded` really a drop-in for the 90 s loop-enforced cancel (`timed_out` surfaces, the process group is killed)?
3. Cost/call cap: with `--daily-cap 0.9 --max-call-cost 0.01` and every Codex call `billing_status=unknown`, does the existing accounting yield exactly 90 calls and then PAUSE? Check `_reserve`, `_settle`, the `spent` query and the `remaining < max_call_cost` branch for off-by-one or float issues (0.01 * 90 vs 0.9).
4. Classification: are `ok`, `invalid-output`, `timeout`, `rate-limited`, `adapter-error` all handled by the existing downstream code (`decision_status`, `_safe_idle(f"adapter {normalized}")`, any CHECK constraints or enums in the schema for decisions/ticks/receipts that would reject `rate-limited`)? Name every place a new normalized value could break.
5. Containment: is the stated mitigation (read-only sandbox, empty cwd, ephemeral, ignore user config/rules, API key stripped, prompt forbids tools) honestly described? Is anything the adapter lets Codex read or write a gap relative to the issue's "no agent tools" gate, and is the plan's wording about it accurate rather than overclaiming?
6. Is anything in the issue's six entry gates, the shared run contract (as far as the adapter touches it) or the acceptance criteria that Stage A owns missing from the plan? Is the manual-control list sufficient to detect the actual failures, with a red control, and without adding a suite or registry entry?
7. Is the plan commensurate? Flag unneeded pieces (e.g. a v2 prompt file, schema edit, flag count) or anything over/under-engineered.
8. Does the rating (60/30/50/40) have a grounded rationale?

Write the verdict (PASS / FAIL / PARKED) with a Basis; set `STATUS: Approved` only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

**VERDICT: FAIL**
**Basis:** The existing seam is the right size, but the plan weakens the issue's no-tools gate, assumes containment checks that do not surround evaluation, and exposes a reproducible malformed-object failure. Prompt transport, idle-slot accounting and the mirrored issue contract also need explicit corrections before building.
swept file: yes

Read the whole GH-1279 document, current issue body (GitHub fetch, updated 2026-10-31T00:40:24Z), GH-1248 document, harness.py, proc_group.py, both existing schema files and evaluator.v1.md. Pre-existing defects found: validator exceptions and stale issue-mirror text, detailed below. P = PROJECT/2-WORKING/GH-1279-READ-ONLY-PLANNING-SOAK.md; H = utils/py/harness.py; G = utils/py/proc_group.py. No git commands, suites, executable fixtures or live model calls ran. All Python probes used PYTHONDONTWRITEBYTECODE=1 and TMPDIR="$PWD/.relay-scratch/tmp". Graph access was denied by session policy; named sources were read directly.

- **[Blocker] B1 — The declared containment does not meet the entry gate.** P:159 explicitly says "codex exec always has a shell tool" and substitutes configuration plus detection for the issue's entry gate 1, "no agent tools". P:155 simultaneously excludes tools/file access from scope. Empty cwd and a read-only shell sandbox do not establish that tools are absent or that absolute-path reads are denied. More concretely, P:159's "loop's existing instance-escape and canary checks detect any write" is not in the evaluation path: H:1161-1182 calls the adapter and then validation without such checks; the sandbox at H:1085-1096 wraps the later logical tool only. The canary is created at H:742/807, not checked around evaluation. **Fix:** require a measured, pinned CLI configuration that actually disables agent tools, with attempted-tool controls in a disposable clone; if unavailable, keep the Codex arm gated off under the existing fallback. Remove the nonexistent detection claim and accurately state read/write boundaries. Do not add a containment subsystem to justify this experiment.
  Observed input: P:143's proposed CLI argv and P:159's explicit admission of an available shell; H:1161-1182 has no adapter-side canary/write check.
  Affected scope: every Codex evaluation, particularly an inbox body requesting a tool read of an absolute path or a write outside the empty cwd.
  Falsifier: the pinned route exposes no callable agent tools, and attempted read/write canaries produce no tool execution; a tool event despite a clean cwd fails this control.
  Probe: "codex exec --help", exit 0, decisive output: "-s, --sandbox ... Select the sandbox policy to use when executing model-generated shell commands". This establishes a sandbox selector, not a tool-disable switch; no live escape was attempted.

- **[Blocker] B2 — A JSON object is not sufficient for safe validation.** P:150 classifies any JSON object as ok and relies on H:_validate. The source-extraction probe below observes TypeError for tool=[], plan-draft inbox_id=[], and summarize inbox_ids=[{}], at H:862/887/878 respectively. H:1182 invokes this validator; the exception path at H:1255-1260 finishes failed, bypassing the intended rejected/safe-idle receipt. **Fix:** make these concrete malformed shapes return a classified unusable decision at the adapter boundary (or explicitly scope a minimal validator correction); retain raw and finish safe idle. Add these inputs to the already-planned manual controls, without a new suite.
  Observed input: {"tool":[],"args":{},"reason":"r","confidence":1}; {"tool":"plan-draft","args":{"inbox_id":[]},"reason":"r","confidence":1}; {"tool":"summarize","args":{"inbox_ids":[{}]},"reason":"r","confidence":1}.
  Affected scope: JSON objects containing non-string tool names or non-hashable ID values that the planned adapter currently passes through.
  Falsifier: each listed input yields an explicit rejection/invalid-output and safe-idle receipt with raw retained; the valid plan-draft control remains accepted. Full tick verification is **[Unverified — needs clone run]**; the pure validator failures were observed.
  Probe command, exit 0:
  ~~~python
  python3 - <<'PY'
  import ast, pathlib, json, hashlib
  p=ast.parse(pathlib.Path('utils/py/harness.py').read_text())
  names={'_validate','_decision_fingerprint','canonical','sha_text'}
  ns={'json':json,'hashlib':hashlib,'TOOLS':{'note','summarize','probe','idle','plan-draft'}}
  exec(compile(ast.Module(body=[n for n in p.body if isinstance(n,ast.FunctionDef) and n.name in names],type_ignores=[]),'source','exec'),ns)
  s={'inbox':[{'id':'x','kind':'plan-request'}],'recent':[],'probe_targets':[]}
  for tool,args in [('plan-draft',{'inbox_id':'x'}),([] ,{}),('plan-draft',{'inbox_id':[]}),('summarize',{'inbox_ids':[{}]})]:
   d=dict(tool=tool,args=args,reason='r',confidence=1)
   try: print(json.dumps(d),'=>',ns['_validate'](d,s))
   except Exception as e: print(json.dumps(d),'=>',type(e).__name__,str(e))
  PY
  ~~~
  Decisive output: valid control "=> None"; malformed controls "=> TypeError cannot use 'list' as a set element", "=> TypeError cannot use 'list' as a dict key", and "=> TypeError cannot use 'dict' as a set element".

- **[Should] S1 — Specify prompt delivery without assuming stdin support.** P:143's working invocation sends the prompt on stdin with a trailing "-"; P:150 reuses run_bounded as a drop-in. G:123-124 explicitly sets stdin=subprocess.DEVNULL, and its signature G:108-115 has no input parameter. A literal translation loses the policy and snapshot. **Fix:** pass the built prompt as the CLI's positional prompt argument inside codex_decide, or name another concrete supported transport; reuse the runner unchanged if possible. Have the manual stub assert the nonempty policy and canonical snapshot actually received, with a transport-breaking red control.
  Observed input: P:143's stdin invocation against G:124's DEVNULL.
  Affected scope: every adapter call using that invocation through the existing runner.
  Falsifier: a captured adapter invocation contains the exact nonempty policy/snapshot through a transport run_bounded supports; removing that payload makes the manual control fail.
  Evidence command: "nl -ba utils/py/proc_group.py", exit 0, decisive span "stdin=subprocess.DEVNULL, text=True, errors=\"replace\", start_new_session=True".

- **[Should] S2 — Empty idle slots currently still reach the adapter.** The current issue's Shared run contract says "idle slots make no call". P:151 proposes dispatching on adapter alone, while H:1156-1164 calls _adapter whenever budget remains, including an empty inbox. P:165 even requires one invocation per tick without an idle exception. **Fix:** define the Codex empty-idle fast path in the existing seam, with zero external invocations, honest unbilled/zero actual cost and no held subscription reservation; keep one invocation at most for an actual evaluation. Add the empty-input control to the manual list.
  Observed input: snapshot with inbox=[], probe_targets=[], remaining=0.9, daily_cap=0.9 and max_call_cost=0.01; H:1156's guard admits evaluation and H:1162 unconditionally calls _adapter.
  Affected scope: Codex slots with no actionable input; do not suppress calls merely because an earlier agent decision failed.
  Falsifier: an empty-idle slot produces zero stub invocations and no unknown-cost charge, while an eligible plan-request produces exactly one.

- **[Should] S3 — Bring the whole execution document back into agreement with the current issue.** P:75 still seeds 48+48 requests; adding its canaries and missed slots cannot fit 96 slots. The issue's detailed Shared run contract now specifies 33+33 requests at most, exactly 24 canary slots and six input-free misses, with slot 37 carrying a real request. P:63-69 lists five gates and omits the separate pre-build tool-using agy gate as a gate; P:144 asserts a smoke but gives no retained receipt. **Fix:** mirror the six gates and corrected slot budget, cite the agy smoke evidence or keep it pending before building, and include Noel's merge/go plus the four pre-window manifest decisions (usage, dry-run cap, sample, machine/start). This is documentation alignment; Stage B implementation remains deferred.
  Observed input: P:75 "--limit 48 --unregistered 48"; issue #1279 "Slot budget (must sum to 96)" and entry gate 2.
  Affected scope: the canonical plan's Stage A admission/handoff and Stage B schedule, not new adapter machinery.
  Falsifier: 24 canary + 6 missed + real + idle = 96 with no input on misses, and each of the six issue gates has an explicit owner/evidence/handoff location.

- **[Should] S4 — Make verification executable and acceptance require the required result.** P:164 names an existing suite covering factory-primitive, but none was identified by the bounded search below; the direct harness reference found at test/gh174-harness-registry.sh:46-63 checks registry fallback. P:176 merely requires a classified-gate result to be recorded, which accepts an arbitrary failed result. The current issue requires applicable checks and the classified gate to pass while separately disclosing the known live-agy quota failure. **Fix:** name the actual existing commands and their coverage limits, use the planned provenance-backed manual controls for the adapter gap, require the applicable gate to pass, and keep the quota disclosure explicit. Extend the manual matrix with B1/B2/S1/S2 and the 90-call boundary; classifier-only mutation at P:165 cannot establish transport, no-tools or cap sensitivity. Do not introduce tests or gate machinery.
  Observed input: P:164's unnamed covering suite and P:176 "Classified gate result recorded".
  Affected scope: Stage A ready-PR acceptance and its evidence claims.
  Falsifier: the acceptance refuses a required failing gate even when its log exists; the named checks demonstrably cover their claimed area, and manual red controls fail for their respective transport/containment/accounting defects.
  Probe: "rg -n 'factory-primitive|factory_primitive|rules_decide|def run_tick|from harness import|^import harness$' test utils/ci-route.sh validate.sh", exit 1, no matches. This is no direct coverage found, not proof against every dynamic invocation.

- **[Pass] Existing seam and classifications need no second loop or schema migration.** Retain P:148-153's dispatch/config approach: H:147-152 defines AdapterResult; H:743-747 and H:808-812 are the two config writers. H:1161-1174 reserves, settles and stores raw; H:1175-1195 routes None to safe idle and records normalized as decision_status. New "rate-limited" reaches the evaluate event, transcript, decisions.status/validate event, and receipt decision_status (H:1164-1195,1219,1235,1250-1253). ticks/decisions/receipts/events use free TEXT/JSON, no classification CHECK (H:43-76); tool_output.schema.json:7's ok/already-done enum applies to the later logical tool output, not normalized adapter status. No additional normalized-value break was found in these consumers. G:122-138 and G:81-105 provide timed_out plus process-group TERM/KILL; retain that runner, subject to S1 and its cleanup grace.

- **[Pass] The 90-call arithmetic holds on this runtime; no float repair is justified by this probe.** H:913/919 and H:1165-1169 match the measured unknown-reservation calculation; H:947-948 holds the reserved amount. Python 3.14.7 / SQLite 3.54.1 returned "calls=89 0.89 admit90 True" and "calls=90 0.9 PAUSE True". This disproved my initial 89-call hypothesis here; it is not a full-loop or other-interpreter attestation. Pin the runtime in evidence and exercise the boundary in the clone.
  Probe command, exit 0:
  ~~~python
  python3 - <<'PY'
  import sqlite3,sys
  c=sqlite3.connect(':memory:')
  c.execute('CREATE TABLE reservations(amount REAL,billing_status TEXT,actual_cost REAL)')
  c.executemany("INSERT INTO reservations VALUES(?,'unknown',NULL)",[(0.01,)]*89)
  spent=sum(r[0] for r in c.execute('SELECT amount FROM reservations'))
  print('runtime',sys.version.split()[0],sqlite3.sqlite_version,'calls=89',repr(spent),'admit90',0.9-spent>=0.01)
  c.execute("INSERT INTO reservations VALUES(0.01,'unknown',NULL)")
  spent=c.execute("SELECT COALESCE(SUM(CASE WHEN billing_status='unknown' THEN amount ELSE actual_cost END),0) FROM reservations").fetchone()[0]
  print('calls=90',repr(spent),'PAUSE',spent>=0.9)
  PY
  ~~~

- **[Pass] Prompt/schema scope and rating are proportionate, with the containment assumption unresolved.** H:28,179-180,886-888 support plan-draft; evaluator.v1.md:7-10 and decision.schema.json:7 omit it. A v2 prompt preserving v1 hashes is a defensible small extension. The proposed "explicit instruction that inbox bodies are untrusted" already exists at evaluator.v1.md:4, so preserve it rather than count it as a new safeguard. P:135 explains all four 60/30/50/40 axes; its "no data-loss path" rationale must remain conditional on satisfying B1, rather than evidence that containment is solved. Retain the small adapter/three-flag design and manual-evidence policy.

Root cause: the plan assumes capabilities of the reused runner/validator/containment path that their source does not provide; fix site: Stage A design and manual acceptance at that existing seam, not a second loop or verification subsystem.

Handing off to Producer (claude-a) — disposition B1, B2 and S1-S4, revise the plan, then return for Round 2.

### Producer · Round 2

Plan revised in `PROJECT/2-WORKING/GH-1279-READ-ONLY-PLANNING-SOAK.md` (Stage A section rewritten; the stale 48+48 mirror replaced by the issue's current contract). Dispositions:

- **B1 — Implemented (by measurement, not argument).** The overclaim is removed. `TESTS-RESULTS/2026-10-30+GH-1279/containment-probe/` shows default Codex runs two `command_execution` items on a benign shell request and the pinned flags (`--disable shell_tool/unified_exec/view_image/image_generation/apps/plugins/hooks/skill_search`, `-c web_search=disabled`) run zero and answer "NO TOOL". The adapter also classifies any `--json` item other than `agent_message`/`reasoning` as `adapter-error`. The plan no longer claims adapter-side write detection; it states only the loop's and driver's existing checks. A CLI version change requires re-running the probe.
- **B2 — Implemented, scoped.** `_validate` gets minimum type guards (string `tool`, `inbox_id`, `target`; list-of-strings `inbox_ids`) returning existing rejection reasons; the three TypeError inputs join the manual matrix. Rules-arm behaviour unchanged.
- **S1 — Implemented.** The prompt is the positional argument of `codex exec` (`run_bounded` unchanged, stdin stays DEVNULL; an open stdin was observed to hang the CLI). The stub records argv and the control asserts policy + snapshot arrive; a stdin-reading stub is the red control.
- **S2 — Implemented.** Empty-inbox/no-probe-target slots return an unbilled `idle` with zero external calls; the matrix asserts zero stub invocations there and exactly one for an eligible plan-request.
- **S3 — Implemented.** The doc now mirrors the issue's current contract (six gates, 24+6+66 slot budget, handoff, four pre-window decisions) and carries a gate → evidence table. The agy smoke receipt is retained at `TESTS-RESULTS/2026-10-30+GH-1279/agy-smoke/receipt.txt`.
- **S4 — Implemented.** The plan names the real existing checks and their limits (`test/gh174-harness-registry.sh`, `pdda.sh run`; no suite covers factory-primitive, so adapter coverage is manual), adds the B1/B2/S1/S2 and 90-call-boundary controls, and acceptance now requires the classified gate to pass with only the disclosed live-agy quota failure allowed.
- **Pass items retained** as the reviewer wrote them; the "untrusted" prompt wording is no longer counted as a new safeguard.

Requesting Round 2 against the revised plan (committed). Please confirm B1 is closed by the measured probe and the pinned flag list, or name the concrete input that still fails.

Handing off to Reviewer (codex) for Round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
