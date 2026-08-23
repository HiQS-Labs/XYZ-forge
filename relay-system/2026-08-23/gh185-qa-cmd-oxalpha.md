# RELAY · GH-185 Gen 3.5 P0 Hardening QA (CmdCode / stealth-ox-alpha)

NEXT: —
STATUS: Approved
ROUND: 3 / 3

## ▶ TAKE YOUR TURN — read this first
1. Read this whole file (header, Setup, Ground rules, Log).
2. Reviewer / Producer protocol completed.

## Setup
- Artifacts under review: PR #185 (`feat/gh180-184-p0-hardening`, head `01479701`) — engine diffs
  (agy's `610193c9` + orchestrator completion `3d87225a`), the four lane suites
  (`test/gh180-repro-timeout-crash.sh`, `test/gh181-repro-adapter-fidelity.sh`,
  `test/gh183-explorer-env-soundness.sh`, `test/gh184-no-tracked-scratch.sh`), the #181 fixture
  amendment, and the verification evidence (15/15 standalone, 262/262 macOS gate, all four suites
  green on the ubuntu canary, canary red = pre-existing #123 backlog, dispositioned on the PR).
- Reviewer: CommandCode (`cmd --model stealth/ox-alpha --effort low`, v1.32.1)
- Producer: GLM 5.3 (orchestrator; engine P0 diff authored by agy)
- Started: 2026-08-23
- Method note: two unbounded-effort runs exceeded the 15-minute turn budget (killed by watchdog);
  the completed review ran at `--effort low` against the trimmed 279-line payload (directives +
  full engine diffs + suite assertion inventories + evidence). Reviewer traced the rewrite regex
  adversarial cases by hand (shell unavailable in `--print` mode).

---

## Log

### Round 1 — Producer (GLM 5.3) — 2026-08-23
**Deliverables Submitted for QA:** PR #185 — lanes #180/#181/#183/#184 completed per their capture
docs: null-exit→124 timeout signature (#180), telemetry→reproducer fidelity with the amended
fixture split (#181: GH-141 record = tokenization, synthetic live record = reproduction,
wrong-cause rc coincidence rejected by signature), explorer clean-env + `--base-env` (#183),
tracked-scratch artifact removal + derived guard (#184); four suites with pre-fix negative-control
baselines; receipts under `TESTS-RESULTS/2026-08-23+GH-174/`.

### Round 2 — Reviewer (CommandCode / stealth-ox-alpha) — 2026-08-23
*(verdict block; full findings as produced — see the review file embedded below)*

**VERDICT: APPROVED** — "The four lane contracts are genuinely pinned with falsifiable negative
controls, the null→124 and signature-gate changes are fail-closed (every identified heuristic
weakness degrades to refusal, never to a wrong reproducer), the clean-env fix provably severs
ambient RELAY_* leakage, and the #181 amendment honestly separates what the historical record can
prove (tokenization) from what the synthetic record proves (reproduction + discrimination)."

Findings summary (full text below): 3 minor (missing-key default conflates absent-with-timeout,
labeled fail-closed; rewrite-heuristic first-match-only/payload-`.sh`/quoted-path failure modes,
all degrading to refusal via the signature gate; signature enforcement removes archival synthesis
— suggest `--allow-unverified`), 6 notes (clean-env PATH inheritance acceptable with `--base-env`
escape; `cmd`-list preference correct; gh181 emitter assertion is a source-text pin — weakest
assertion in the PR; gh184 negative control nearly tautological but acceptable; suite
environment-sensitivity low, gh183's shim-contract pin is load-bearing brittleness; #181 split
sound, end-to-end real-record flow worth revisiting on the next live spaced-path defect; safety
clean — heuristic can only shorten to repo-relative, cannot redirect outside the checkout).

**Required changes: none blocking.** Recommended follow-ups (non-gating): iterate the rewrite over
all absolute-path matches; an `--allow-unverified` archival escape hatch; a behavioral emitter
assertion replacing the source-grep pin.

### Round 3 — Producer disposition (GLM 5.3) — 2026-08-23
- **Accepted (filed as follow-ups, non-gating):** all three reviewer recommendations — rewrite-all-
  matches, `--allow-unverified`, behavioral emitter assertion — consolidated into the QA follow-up
  issue filed 2026-08-23 and noted on #174; they fold into #174's existing hardening tasks rather
  than gating this PR.
- **Accepted as-is (documented, no action):** the three minor findings are confirmed real but
  fail-closed by the signature gate (the reviewer's own analysis); the gh183 brittleness is
  load-bearing; the gh184 phrasing point acknowledged.
- **Status: Approved. PR #185 proceeds to merge on the strength of the local macOS gate (262/262,
  the authoritative gate per GH-509) + this relay.**

---

### Reviewer output — verbatim

All artifacts reviewed — parser, both engine commits, all four suites, plus analytical probing of the rewrite regex (shell was unavailable, so I traced the adversarial cases by hand against the regex semantics).

## Findings

- [SEVERITY: minor] Missing-key default of 124 conflates "field absent" with "timed out" (`repro_builder.py:67`) — a record that simply omits `exit_code` (crashed emitter, unknown status) is labeled a timeout. This is fail-closed: `main()`'s new signature gate then refuses to emit anything unless the target really exits 124 with the signature (gh180's negative control proves exactly this), so no false repro is fabricated. But the record's normalized `exit_code: 124` is semantically wrong for archival. A distinct "unknown" state or explicit `timed_out: true` field would be cleaner.
- [SEVERITY: minor] Path-rewriting heuristic (`repro_builder.py:38-48`) has real failure modes: (1) **multiple absolute paths** — only the first match is rewritten; `bash /a/tool.sh --flag /other/x.sh` leaves `/other/x.sh` absolute, breaking hermeticity of the baked repro; (2) **`.sh` inside argument payloads** — `tool.sh --note "see /docs/run.sh for help"` rewrites prose inside a quoted string if a same-named file happens to exist under repo_root, corrupting argv; (3) **quoted paths** — `'/abs/x.sh'` followed by `'` matches neither `\s` nor `$`, so the path is left absolute (unquoted joins from `" ".join(cmd)` do match, which covers the actual GH-141 shape); (4) **relative `.sh` tokens** are correctly untouched. Mitigating factor keeping this minor: every misrewrite is caught downstream by the mandatory initial-reproduction gate (mis-tokenized command won't reproduce → exit 2), so corruption degrades to refusal, never to a wrong reproducer. Worth a TODO to iterate over all matches, not just the first.
- [SEVERITY: minor] Signature-match enforcement before build does break legitimate archival use — you can no longer synthesize a reproducer artifact for a historical/fixed defect (ddmin previously degraded gracefully by returning items unchanged; now it's a hard rc 2). The #181 suite *codifies* the refusal, so it's clearly intentional, and the rationale is sound (an unverified repro is worse than none). Suggest an explicit opt-out flag (e.g. `--allow-unverified`) rather than leaving archival users with no path at all.
- [SEVERITY: note] Explorer clean-env (`active_explorer.py`) still inherits the runner's `PATH` — ambient venv/tool versions can influence probe outcomes even though `RELAY_*` cannot. Probes legitimately needing more env (LANG/LC_ALL locale-sensitive shims, XDG dirs, SSH agent) will see different behavior than production; `--base-env` is the declared escape hatch, which is adequate. `XYZ_ROOT` defaulting to `cwd` is sensible.
- [SEVERITY: note] Preferring `cmd` (list) over `command` (joined) is correct: the list is lossless across spaced paths, while the joined string is ambiguous. Consistency confirmed — `parse_failure_telemetry` already prefers `"cmd"` when present (`repro_builder.py:34`). Keeping both preserves backward compatibility for old consumers; no issue.
- [SEVERITY: note] gh181's emitter assertion (`grep '"cmd": cmd,'` against source, line 116) is a source-text pin, not a behavioral test — it would pass on dead code and doesn't exercise `run_harness`. Cheap and directionally right, but the weakest assertion in the PR.
- [SEVERITY: note] gh184's negative control is close to tautological: it proves `git ls-files` lists a committed file, i.e. it exercises git, not a separate guard tool. Since the suite itself *is* the guard (derived, no hand-maintained list), this is acceptable, but the "guard detects" phrasing overstates it slightly.
- [SEVERITY: note] Suite environment sensitivity is low: gh180/181/184 are hermetic (mktemp fixtures, fixture-guard, cleanup traps); gh183's assertion 2 runs the real `relay-automation/agy-turn.sh` and asserts every probe hits rc 2 — correctly pinned to the shim's contract but brittle to future shim changes, and a probe timeout (rather than rc 2) would fail the suite. That brittleness is load-bearing here, not a defect. Nothing macOS-vs-linux fragile spotted; parallel-load risk minimal since each suite uses isolated `$WORK`.
- [SEVERITY: note] The #181 split is sound: tokenization (real spaced-path record), reproduction (synthetic live record, rc 7 + signature), wrong-cause rejection (rc-coincident twin without signature) each pin one contract, and the amendment honestly documents that GH-141's defect is historical (fixed by GH-156). What's lost: no end-to-end proof that the pipeline handles a *real-world* record shape through build-to-reproduction (the synthetic record uses a list-form `cmd`, sidestepping the string-tokenization + rewrite + reproduce path in one flow — the GH-141 record proves parsing but its build is asserted to *refuse*). Acceptable given the defect is genuinely fixed; worth revisiting when the next real live spaced-path defect arrives.
- [SEVERITY: note] Safety/scope clean: emitted reproducers `cd "$ROOT"` and execute in the live checkout, but that's pre-existing design, sandboxed via mktemp + fixture-guard; no tracked-scratch mutation; changes confine to the four lanes' surfaces plus validate.sh registration and receipts. The rewrite heuristic only ever shortens paths to repo-relative — it cannot redirect execution outside the checkout.

## Required changes (if any)

None blocking. Recommended follow-ups (non-gating):
- Iterate the rewrite over **all** absolute-path matches, not just the first.
- Consider an `--allow-unverified` escape hatch for archival reproducer synthesis.
- Replace gh181's source-grep emitter assertion with a behavioral call to `run_harness` when convenient.

## Verdict

VERDICT: APPROVED

The four lane contracts are genuinely pinned with falsifiable negative controls, the null→124 and signature-gate changes are fail-closed (every identified heuristic weakness degrades to refusal, never to a wrong reproducer), the clean-env fix provably severs ambient `RELAY_*` leakage, and the #181 amendment honestly separates what the historical record can prove (tokenization) from what the synthetic record proves (reproduction + discrimination). Remaining findings are quality notes and non-gating robustness improvements to the rewrite heuristic.
