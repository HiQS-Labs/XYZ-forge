# RELAY · Side Quest plan QA - Local LLM benchmark on Apple Silicon (HiQS-AI-Resolve-Catalog#5)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-28.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(sidequest-llm-bench-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/sidequest-llm-bench-plan.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/.cache/sidequest-relay/sidequest-llm-bench-plan.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-28
- Definition of Done: **Approved** when all of these hold:
  - (a) every tool name, CLI command and flag in the plan is accurate for current releases (mlx-lm `mlx_lm.benchmark`/`mlx_lm.generate`, llama.cpp `llama-bench`, ANEMLL `tests/chat.py` + ANE profiler, Geekbench AI, MLX Swift `LLMEval`, `powermetrics` samplers), or is explicitly hedged;
  - (b) the methodology is fair across the three devices (identical files, warm-up, ≥3 trials, power/thermal controls, prefill vs decode separated, cross-runtime caveat);
  - (c) no important measurement is missing for the three stated questions (ANE fallback detection, tok/s per watt, memory footprint/swap, sustained throttling);
  - (d) the plan stays "light-medium": no over-engineering, and nothing load-bearing missing;
  - (e) the checklist is complete and each item is actionable; done criteria are testable;
  - (f) no invented spec numbers or expected results for M6 / M4 Pro / M5.

## Review packet

**What this is.** A side-quest benchmark PLAN (no code yet) for local LLM inference on Apple Silicon: an M6 Mac (GPU neural accelerators; user reports a 32-core ANE), an M4 Pro MacBook Pro 14" baseline (no GPU neural accelerators), and an M5 iPad. It is filed as GitHub issue HiQS-Labs/HiQS-AI-Resolve-Catalog#5. The artifact is `.relay-artifacts/sidequest-llm-bench-plan.md` (identical to the issue body).

**Operational envelope.** A single operator, three personal devices, a few evenings of work. The operator expects to pivot during testing, so the plan should be pragmatic. Grade against "light-medium": don't ask for CI, dashboards, statistical frameworks or extra devices/models unless something load-bearing is missing. You may use web knowledge. Mark any claim you cannot check as `[Unverified]` rather than guessing.

**Read:** the artifact, in full.

**Questions** (cite artifact line numbers, e.g. `plan:48`):

1. **Tool/flag accuracy.**
   - Are the `mlx_lm.benchmark` flags right (`-p`, `-g`, `-n`; `-p` takes a single int)?
   - Is TTFT ≈ prompt_tokens / prompt_tps a fair derivation?
   - Are the `llama-bench` flags right (`-p 512,2048,8192 -n 128 -r 5 -fa on -o csv`)?
   - Is `python tests/chat.py --meta <dir>/meta.yaml --prompt` the right ANEMLL invocation?
   - Is `powermetrics --samplers cpu_power,gpu_power,ane_power -i 1000` right?
   - Is anything stale or wrong?
2. **Model picks.**
   - Are the Qwen3 1.7B / 8B / 30B-A3B picks and the exact repo names (`mlx-community/*-4bit`, `unsloth/Qwen3-1.7B-GGUF`, `Qwen/Qwen3-8B-GGUF`, `Qwen/Qwen3-30B-A3B-GGUF`, `anemll/anemll-Qwen-Qwen3-1.7B-ctx2048_0.3.5`, and the gpt-oss-20b fallback) sensible and justified?
   - Is the set small enough?
3. **Fairness.**
   - Is anything in the methodology biased toward one device or runtime? Consider prefill vs decode, context lengths, quantization mismatch between MLX 4-bit and GGUF Q4_K_M, High Power mode, thermals, and iPad vs Mac.
4. **Missing measurements.**
   - Is the ANE fallback check adequate (op placement plus non-zero `ane_power`)?
   - Is tok/s per watt derived correctly?
   - Are memory footprint and swap captured?
   - Is the sustained-throttling run adequate?
   - What else, if anything, is load-bearing and missing?
5. **Right-sizing.** Is anything over-built that should be cut, or under-built?
6. **Checklist and done criteria.** Is each item actionable? Is anything missing or redundant? Are the done criteria testable?
7. **Invented numbers.** Does the plan state or imply any spec or expected result it shouldn't?

Write findings in the Log per the turn rules. Set `STATUS: Approved` only if the Definition of Done is met.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · agy

swept file: yes
pre-existing defects in file: none observed beyond the findings graded below.

#### Definition of Done Assessment
- **(a) Tool names, CLI commands, and flags:** Mostly accurate and well-hedged, but `llama-bench` uses integer syntax for Flash Attention (`-fa 1` rather than `-fa on`), and ANEMLL's tok/s reporting requires `tests/chat_full.py` rather than `tests/chat.py`.
- **(b) Methodology fairness:** Prefill vs decode cleanly isolated, warm-up (1 discarded run, ≥3 trials with mean ± stddev) specified, thermal/power controls documented. iPad fairness needs explicit display Auto-Lock disabling.
- **(c) Measurement completeness:** ANE fallback verification and sustained throttling runs are thorough. Power breakdown in `results.csv` needs `gpu_power_w` and `ane_power_w` alongside package `avg_power_w` to answer Goal Q3 directly.
- **(d) Light-medium sizing:** Kept lean and pragmatic; avoids over-engineered evaluation harnesses.
- **(e) Checklist & done criteria:** Complete, phased logically (Phase 0–6), and testable against concrete outputs.
- **(f) Invented numbers:** None. All specs are marked `_record_`, with M6 ANE cores hedged (`user reports 32`) and M6 GPU accelerators noted as `believed`.

---

#### Findings

- `[Pass]` **MLX benchmark flags & derivation (`plan:48`):** `mlx_lm.benchmark --model <repo> -p <P> -g 128 -n 5` is exact; the plan correctly specifies that `-p` takes a single integer and requires looping across prompt lengths.
- `[Pass]` **Model matrix selection (`plan:35-39`):** The 3-tier hierarchy (`Qwen3-1.7B`, `Qwen3-8B`, `Qwen3-30B-A3B`) with `gpt-oss-20b` fallback is compact and directly mirrors the reference models used in Apple's M5/MLX write-up.
- `[Pass]` **Hardware spec discipline (`plan:17, plan:21-25`):** The matrix explicitly states "No expected numbers are assumed for any device" and uses `_record_` placeholders without speculating on performance.
- `[Pass]` **ANE fallback check (`plan:67`):** Requiring both compute-unit op placement (`anemll-profile` / Xcode Core ML Performance Report) and non-zero `ane_power` prevents false positives from CPU/GPU fallback.
- `[Pass]` **Powermetrics samplers (`plan:52`):** `sudo powermetrics --samplers cpu_power,gpu_power,ane_power -i 1000` is valid on Apple Silicon macOS and captures individual rail and package telemetry.

- `[Should]` **Correct `llama-bench` Flash Attention flag syntax (`plan:49`)**
  - **Observed input:** `plan:49`: `llama-bench -m <gguf> -p 512,2048,8192 -n 128 -r 5 -fa on -o csv`
  - **Affected scope:** All `llama-bench` CLI invocations in Phase 2 (`plan:49, plan:105`).
  - **Falsifier:** Executing `llama-bench` with `-fa on` against `llama.cpp` builds where `-fa` expects an integer boolean (`1` or `0`) or comma-separated list (`-fa 1` or `-fa 0,1`), resulting in argument parsing errors.
  - **Fix:** Update `-fa on` to `-fa 1` in `plan:49` and `plan:105`.

- `[Should]` **Point ANEMLL tok/s measurements to `tests/chat_full.py` (`plan:50, plan:109`)**
  - **Observed input:** `plan:50`: `ANEMLL: python tests/chat.py --meta <model>/meta.yaml --prompt "<fixed prompt>"` and `plan:109`: `Run chat.py with the fixed prompt on both Macs. Record prefill/decode t/s.`
  - **Affected scope:** ANEMLL throughput and latency data collection in Phase 3.
  - **Falsifier:** Running `python tests/chat.py` in the ANEMLL repository, which functions as a basic sanity check and does not output runtime tokens/second metrics, whereas `tests/chat_full.py` (or `anemll-bench`) implements real-time generation metrics and tok/s logging.
  - **Fix:** Update `plan:50` and `plan:109` to specify `tests/chat_full.py` (or note `anemll-bench`) for collecting prefill/decode tok/s.

- `[Should]` **Add individual power rails (`gpu_power_w`, `ane_power_w`) to `results.csv` schema (`plan:88`)**
  - **Observed input:** `plan:88`: `run_id, ..., avg_power_w, tok_per_joule, thermal_state, ...`
  - **Affected scope:** Goal Q3 analysis comparing ANE vs GPU power draw (`plan:9, plan:111`).
  - **Falsifier:** Logging ANE benchmark runs where only package `avg_power_w` is recorded, making it impossible to separate ANE rail draw from package idle/DRAM overhead to compare directly with GPU rail draw.
  - **Fix:** Add `gpu_power_w` and `ane_power_w` columns to `results.csv` in `plan:88`, or note in `plan:66` that rail breakdowns from `powermetrics` should be logged into `notes`.

- `[Nit]` **Document iPad Auto-Lock setting (`plan:59`):** On iPadOS, display sleep / auto-lock suspends or throttles background execution. In `plan:59`, add "Auto-Lock set to Never" alongside "Low Power Mode off".
- `[Nit]` **Clarify TTFT derivation scope (`plan:48`):** `TTFT ≈ prompt_tokens / prompt_tps` calculates prompt prefill evaluation time ($T_{prefill}$). True TTFT is $T_{prefill} + 1/gen\_tps$ (including first token generation). Note parenthetically that this represents prefill compute latency.
- `[Nit]` **iPad power telemetry expectation (`plan:84, plan:88`):** Note in `plan:84` or `plan:88` that `avg_power_w` and `tok_per_joule` on iPad will be `na` unless using an external hardware USB-C power meter, since `powermetrics` is macOS-only.

---

**VERDICT: FAIL**
**Basis:** The benchmark plan is well-scoped, disciplined about not inventing specs, and light-medium. However, it requires three actionable adjustments before approval: correcting `llama-bench` flag syntax (`-fa 1`), directing ANEMLL metrics extraction to `tests/chat_full.py`, and recording GPU/ANE rail power in the schema to fully answer Goal Q3.

handing off to claude-a — go to the claude-a window and say 'take your turn'

### Producer · Round 1 · claude-a

The artifact has been regenerated as plan v2 (`.relay-artifacts/sidequest-llm-bench-plan.md` is re-seeded for this round). Dispositions:

- **[Should] llama-bench `-fa on` → `-fa 1`: Declined, with a hedge added.** The current upstream README lists `-fa, --flash-attn <on|off|auto> (default: auto)` (ggml-org/llama.cpp `tools/llama-bench/README.md:68`, fetched 2026-09-28). The Debian `llama-bench(1)` manpage agrees. `-fa on` is correct for current builds. The integer form belongs to older builds, so v2 keeps `-fa on` and adds "(older builds use `-fa 1`)" to the runtime matrix.
- **[Should] ANEMLL `tests/chat.py` → `tests/chat_full.py`: Declined, because the observed claim is false.** Upstream `tests/chat.py` prints the metrics itself: `print(f"\nPrefill: {prefill_ms:.1f}ms ({prefill_tokens_per_sec:.1f} t/s)")` and `print(f"Inference: {inference_tokens_per_sec:.1f} t/s")` (Anemll/Anemll `tests/chat.py:1536-1538`, main, fetched 2026-09-28). `chat_full.py` is the multi-turn history variant. `anemll-bench` measures ANE bandwidth on its own lm_head models, not end-to-end LLM tok/s. v2 now names the exact `Prefill:`/`Inference:` lines to record (Phase 3).
- **[Should] add `gpu_power_w` / `ane_power_w` columns: Implemented.** Added to the schema. Methodology now requires storing the GPU and ANE rails separately for Q3.
- **[Nit] iPad Auto-Lock: Implemented** ("Auto-Lock set to Never" in the same-conditions list).
- **[Nit] TTFT derivation: Implemented.** Prefill latency ≈ prompt_tokens/prompt_tps. `ttft_s` = prefill + 1/gen_tps, labelled as derived.
- **[Nit] iPad power `na`: Implemented** in Methodology and the Scaffold note (power fields are `na` unless an external USB-C meter is used).

ROUND bumped to 2. Handing off to Reviewer (agy): please re-review plan v2 against the DoD, and check specifically that the two declines are backed by the cited sources.

### Round 2 · Reviewer · agy

swept file: yes
pre-existing defects in file: none observed.

#### Definition of Done Assessment
- **(a) Tool names, CLI commands, and flags:** All verified and accurate for current releases. The Producer's decline of `-fa 1` in favor of `-fa on` is confirmed via upstream `llama.cpp` documentation (`tools/llama-bench/README.md:68`), and the hedge `(older builds use -fa 1)` at `plan:49` provides safe backward compatibility. The Producer's decline of `tests/chat_full.py` is likewise confirmed; upstream `tests/chat.py` directly logs `Prefill: … t/s` and `Inference: … t/s`, which `plan:109` now explicitly targets.
- **(b) Methodology fairness:** Identical files (SHA-256 pinned), warm-up (1 discarded run, ≥3 trials with mean ± stddev), and power/thermal controls are specified across all three devices. iPad testing explicitly specifies `Auto-Lock set to Never` at `plan:59`. Prefill and decode are separated.
- **(c) Measurement completeness:** All three target questions are fully addressed. `gpu_power_w` and `ane_power_w` are integrated into the `results.csv` schema (`plan:88`) and methodology (`plan:66`) to resolve Q3. TTFT derivation is documented as `ttft_s = prefill + 1/gen_tps` (`plan:48`). ANE fallback detection requires op placement and non-zero `ane_power`.
- **(d) Light-medium sizing:** Remains pragmatic and lean; avoids extraneous benchmarking machinery.
- **(e) Checklist & done criteria:** Complete, phased logically (Phase 0–6), and testable against concrete outputs.
- **(f) Invented numbers:** None. All specs and expected results use `_record_` placeholders, with M6 accelerators marked as `believed` and ANE core count clearly attributed (`user reports 32`).

---

#### Findings

- `[Pass]` **llama-bench Flash Attention syntax & hedge (`plan:49`):** Verified upstream `llama-bench` flag syntax (`-fa on|off|auto`); `plan:49` accurately specifies `llama-bench -m <gguf> -p 512,2048,8192 -n 128 -r 5 -fa on -o csv` and includes the backward-compatibility hedge `(older builds use -fa 1)`.
- `[Pass]` **ANEMLL metric extraction target (`plan:50, plan:109`):** Verified upstream `tests/chat.py` prints `Prefill: … t/s` and `Inference: … t/s`; `plan:109` instructs to "Record the `Prefill: … t/s` and `Inference: … t/s` lines it prints."
- `[Pass]` **Dedicated power rails in schema & methodology (`plan:66, plan:88`):** `plan:66` specifies "Store the average combined W **plus the GPU and ANE rails separately** (`gpu_power_w`, `ane_power_w`), which Q3 needs", and `plan:88` includes `gpu_power_w, ane_power_w` in `results.csv`.
- `[Pass]` **iPad Auto-Lock control (`plan:59`):** `plan:59` specifies "on the iPad, Low Power Mode off and Auto-Lock set to Never".
- `[Pass]` **Derived TTFT formulation (`plan:48, plan:88`):** `plan:48` specifies "record it as `ttft_s` = prefill + 1/gen_tps and label it derived", matching `ttft_s` in the schema (`plan:88`).
- `[Pass]` **iPad power telemetry expectation (`plan:66, plan:84`):** `plan:66` specifies "iPad power columns are `na` unless an external USB-C power meter is used", and `plan:84` confirms "iPad power fields are `na` (see Methodology)."

---

**VERDICT: PASS**
**Basis:** All Round 1 findings have been resolved or soundly declined with upstream evidence. Plan v2 satisfies all criteria (a)-(f) of the Definition of Done.

relay closed (Approved), no further turn needed

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
