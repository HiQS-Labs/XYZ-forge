# RELAY · GH-1279 Stage A build and final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh1279-stagea-build): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the Stage A adapter diff against `origin/development` (`utils/py/harness.py`, `utils/py/factory_primitive/prompts/evaluator.v2.md`, `utils/py/factory_primitive/schemas/decision.schema.json`), implementing the approved plan in `PROJECT/2-WORKING/GH-1279-READ-ONLY-PLANNING-SOAK.md` section "Stage A plan" (plan QA: `relay-system/2026-10-30/gh1279-stagea-plan-qa.md`, Approved).
- Reviewer: codex   ·   Producer: agy (builder)
- Started: 2026-10-30
- Definition of Done: the plan's "Acceptance (Stage A)" list.

## PRODUCER BUILD SPEC (agy, Round 1) — implement exactly this, nothing else
Read the plan section first. You may edit ONLY: `utils/py/harness.py`, `utils/py/factory_primitive/schemas/decision.schema.json`, and create `utils/py/factory_primitive/prompts/evaluator.v2.md`. No tests, no other files, no refactors. Keep style and comment density of the surrounding code. When done run `python3 -m py_compile utils/py/harness.py`, then append your Producer block to this file (list the edits), set `NEXT: Reviewer`, and hand off.

1. `AdapterResult` (harness.py ~l.147): add a last field `called: bool = True`. Every existing construction stays valid. In `run_tick`, change the evaluate emit `agent_called=True` (~l.1164, the one after `_adapter`) to `agent_called=result.called`. Leave the `budget-exhausted` emit (`agent_called=False`) alone.
2. Imports: add `tempfile` (and `re` is already imported). `run_bounded` is already imported.
3. Add near `rules_decide` a module constant `CODEX_FLAGS` (tuple): `-s read-only --ephemeral --ignore-user-config --ignore-rules --skip-git-repo-check`, then `--disable X` for each of exactly these eight: `shell_tool unified_exec view_image image_generation apps plugins hooks skill_search`, then `-c web_search=disabled --json`.
4. Add `codex_decide(snapshot: dict, config: dict) -> AdapterResult` after `rules_decide`:
   - Empty-idle fast path: if `not snapshot["inbox"] and not snapshot["probe_targets"]`: `d = _decision("idle", {}, "no actionable input (no agent call)")` and `return AdapterResult(canonical(d), "ok", d, 0.0, "unbilled", called=False)`.
   - Otherwise build `prompt = (PACKAGE/"prompts"/"evaluator.v2.md").read_text(encoding="utf-8") + "\n\nSnapshot (JSON):\n" + canonical(snapshot)`.
   - Use `tempfile.TemporaryDirectory(prefix="fp-codex-")` as `d`; out file `d/"last.json"`. argv = `[os.environ.get("CODEX_BIN","codex"), "exec", *CODEX_FLAGS, "-m", config["codex_model"], "-C", d, "-o", str(out_file), prompt]` (prompt is the positional argument; no stdin). env = `os.environ` copy without `OPENAI_API_KEY`.
   - `res = run_bounded(argv, cwd=d, env=env, timeout=config["adapter_timeout_s"])`. If it raises `OSError`: return `AdapterResult("", "adapter-error", None, 0.0, "unbilled", called=False)`.
   - If `res.timed_out`: `AdapterResult((res.stdout or "")[-2000:], "timeout", None, None, "unknown")`.
   - text = `res.stdout + res.stderr`. If `res.returncode != 0`: normalized `rate-limited` if `re.search(r"429|rate.?limit|usage.?limit|quota", text, re.I)` else `adapter-error`; return `AdapterResult(text[-2000:], normalized, None, None, "unknown")`.
   - Tool detection: for each line of `res.stdout` that parses as a JSON object with `type` in (`item.started`, `item.completed`) whose nested `item.type` is not in (`agent_message`, `reasoning`): return `AdapterResult(res.stdout[-2000:], "adapter-error", None, None, "unknown")`. Lifecycle events without an item (`thread.started`, `turn.started`, `turn.completed`) are ignored.
   - Message: `raw = out_file.read_text(encoding="utf-8").strip()` if the file exists else `""`. If empty -> `invalid-output`. Else `json.loads(raw)` in try; a non-dict or a decode error -> `AdapterResult(raw, "invalid-output", None, None, "unknown")`; a dict -> `AdapterResult(raw, "ok", parsed, None, "unknown")`. Never retry. Never raise.
5. `_adapter(snapshot, fault)` -> `_adapter(snapshot, fault, config)`; keep the four fault branches first, unchanged; then `if config.get("adapter") == "codex": return codex_decide(snapshot, config)`; else `rules_decide`. Update the one call site in `run_tick` (`_adapter(snapshot, fault, config)`; `config` is already in scope there).
6. `_validate` type guards (return existing reason strings; rules-arm behaviour unchanged): after the shape check, `if not isinstance(tool, str) or tool not in TOOLS or not isinstance(args, dict): return "tool-or-args-not-allowlisted"`. In the `note` branch require `isinstance(args.get("inbox_id"), str)` else `"note-args"`; in `summarize` require every element of `args["inbox_ids"]` to be a `str` else `"summarize-args"` (check before the set/len dedupe and the `pending.get`); in `probe` require `isinstance(args.get("target"), str)` else `"probe-target-not-eligible"`; in `plan-draft` require `isinstance(args.get("inbox_id"), str)` else `"plan-draft-id-not-eligible"`.
7. Config: add `adapter_config(adapter: str, model: str | None, timeout: float) -> dict` (module level): for `rules` return `{"adapter":"rules","prompt_sha256": sha_text(v1 prompt text)}`; for `codex` return `{"adapter":"codex","codex_model":model,"adapter_timeout_s":timeout,"codex_flags":list(CODEX_FLAGS),"prompt_sha256": sha_text(v2 prompt text)}`. In both `init_instance` and `init_from_prs`, add a keyword parameter `adapter_cfg: dict | None = None` and after building `config` do `config.update(adapter_cfg or adapter_config("rules", None, 90.0))` (this overrides the existing `prompt_sha256` key; keep the rest).
8. CLI (`factory_parser`, init subparser): `--adapter` choices `["rules","codex"]` default `"rules"`; `--codex-model` default None; `--adapter-timeout` type float default 90.0. In `factory_main`'s init branch, before seeding: if `args.adapter == "codex" and not args.codex_model: raise ValueError("--adapter codex requires --codex-model")`; if `args.adapter_timeout <= 0` raise ValueError; build `cfg = adapter_config(args.adapter, args.codex_model, args.adapter_timeout)` and pass `adapter_cfg=cfg` to `init_from_prs` / `init_instance`.
9. `evaluator.v2.md`: the exact text of `evaluator.v1.md` plus (a) a bullet `- \`plan-draft\`: handle the oldest eligible \`plan-request\` with args \`{"inbox_id": <id>}\`.` placed with the other tool bullets and (b) a final line `Return only the bare JSON object: no prose and no code fence.` Do not edit `evaluator.v1.md`.
10. `decision.schema.json`: add `"plan-draft"` to the `tool` enum. Nothing else.


## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1 (agy)

Implemented the Stage A adapter spec in full:
1. `AdapterResult` (`utils/py/harness.py`): added `called: bool = True`. Updated evaluate event emission in `run_tick` to `agent_called=result.called` while preserving `budget-exhausted` (`agent_called=False`).
2. Added `import tempfile` to imports in `utils/py/harness.py`.
3. Added `CODEX_FLAGS` tuple near `rules_decide` with `-s read-only --ephemeral --ignore-user-config --ignore-rules --skip-git-repo-check`, the 8 `--disable` flags (`shell_tool`, `unified_exec`, `view_image`, `image_generation`, `apps`, `plugins`, `hooks`, `skill_search`), `-c web_search=disabled`, and `--json`.
4. Added `codex_decide(snapshot: dict, config: dict) -> AdapterResult` after `rules_decide`:
   - Empty-idle fast path: if `not snapshot["inbox"] and not snapshot["probe_targets"]`, returns canonical `idle` decision with `unbilled`, `0.0`, and `called=False`.
   - Assembles prompt from `evaluator.v2.md` + snapshot JSON.
   - Runs `run_bounded` in `tempfile.TemporaryDirectory` with `OPENAI_API_KEY` scrubbed from env.
   - Handles `OSError` -> `adapter-error` with `unbilled` and `called=False`.
   - Handles `timed_out` -> `timeout` with `unknown`.
   - Classifies non-zero exits as `rate-limited` (regex match for 429/rate-limit/usage-limit/quota) or `adapter-error` with `unknown`.
   - Detects tool execution: any JSON line in `stdout` with `item.started`/`item.completed` whose item is not `agent_message` or `reasoning` returns `adapter-error` with `unknown`. Lifecycle events without item are ignored.
   - Reads output JSON from file, validates dict structure, classifies empty/malformed as `invalid-output`.
5. Updated `_adapter(snapshot, fault, config)` to accept `config`, dispatching to `codex_decide` when `config.get("adapter") == "codex"` and falling back to `rules_decide`. Updated the call site in `run_tick`.
6. Hardened `_validate` type guards:
   - Tool and args shape: requires `isinstance(tool, str)`, `tool in TOOLS`, and `isinstance(args, dict)` else returns `"tool-or-args-not-allowlisted"`.
   - `note`: requires `isinstance(args.get("inbox_id"), str)` else `"note-args"`.
   - `summarize`: requires all items in `args["inbox_ids"]` to be `str` before dedupe and membership checks, else `"summarize-args"`.
   - `probe`: requires `isinstance(args.get("target"), str)` before target set lookup, else `"probe-target-not-eligible"`.
   - `plan-draft`: requires `isinstance(args.get("inbox_id"), str)` before pending map lookup, else `"plan-draft-id-not-eligible"`.
7. Added `adapter_config(adapter, model, timeout)` generating config for `rules` and `codex` (with prompt hashes and flags). Updated `init_instance` and `init_from_prs` with `adapter_cfg: dict | None = None` keyword argument.
8. Added CLI arguments to `factory_parser` init subparser (`--adapter`, `--codex-model`, `--adapter-timeout`). Updated `factory_main` init handler to validate arguments, build config, and pass `adapter_cfg` to initializers.
9. Created `utils/py/factory_primitive/prompts/evaluator.v2.md` matching `evaluator.v1.md` plus the `plan-draft` bullet and the final bare JSON instruction. Left `evaluator.v1.md` untouched.
10. Added `"plan-draft"` to the `tool` enum in `utils/py/factory_primitive/schemas/decision.schema.json`.

Verification:
- Compiled cleanly with `python3 -m py_compile utils/py/harness.py`.
- Verified type guards, `codex_decide` mock outcomes (tool detection, rate-limit, timeout, OSError, valid dict, empty idle), `AdapterResult.called`, and CLI parsing via inline test harnesses.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
