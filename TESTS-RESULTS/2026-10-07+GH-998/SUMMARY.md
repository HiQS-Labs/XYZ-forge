# GH-998 — first ADK evidence quick wins

The selected documented commands work with explicit prerequisites and substitutions. One rated-row preview needs the already-documented deliberate force flag. Retained marathon records support a partial action sequence and a distinct failed-gate witness; they do not support a full tool-call score or a whole-marathon success claim.

Scope: [#998](https://github.com/HiQS-Labs/XYZ-forge/issues/998), adopting items 1–2 of [#996's consolidated comment](https://github.com/HiQS-Labs/XYZ-forge/issues/996#issuecomment-6053498474), whose numbering differs from the issue body. No runtime code, new test suite, ADK dependency, or historical external action was executed.

## Revisions and evidence boundaries

- Current source baseline: Forge `38ac9ee43bdedbd25be0cfec2029b0a27abd70a1`, fresh full GitHub clone off development. Current probe HEADs/timestamps/exits are recorded in [provenance.jsonl](provenance.jsonl); the scripts being checked are unchanged from that integration baseline.
- Earlier comparison baseline: Forge `062ae45f01faf73bf78bcc10fcba86cd7d5c2ad7`; ADK fork `a01b226845b3343f788a7df10e337cad412f544b`. Both primary local checkouts were verified clean and left untouched.
- Operator date for this work is 2026-10-07; UTC probe timestamps fall on 2026-10-08. Historical GH-648 and GH-862 observations are September records, not reruns today.
- [ADK trajectory matching implementation](https://github.com/noelsaw1/adk-python-fork/blob/a01b226845b3343f788a7df10e337cad412f544b/src/google/adk/evaluation/trajectory_evaluator.py#L147) compares actual and expected tool uses with exact/in-order/any-order branches. [Its tests](https://github.com/noelsaw1/adk-python-fork/blob/a01b226845b3343f788a7df10e337cad412f544b/tests/unittests/evaluation/test_trajectory_evaluator.py#L114) include equal calls and rejected different names/arguments. Those files were read; ADK tests were not run. Borrow the explicit expected-versus-observed discipline, not the SDK/evalset representation. ADK's application runtime and Forge's external CLI/skills orchestration remain different layers.

## Selected command audit

Run from the owned Forge task clone, with Python 3 and Node available, the existing ledger/schema present, and `PYTHONDONTWRITEBYTECODE=1`. These are five safe examples plus one classified external-action example; controls are variants of the same examples. The retained outputs replace only the task-root and user-home paths with placeholders. Every current probe compared existing `releases.db`, `releases.sql`, and preview bytes before/after: unchanged.

| Example / source at integration baseline | Category and exact substitution | Expected / observed | Retained output and limit |
|---|---|---|---|
| [ROUTER](../../ROUTER.md), lines 30 and 188: roadmap list | Read-only: `python3 utils/py/releases_app.py roadmap list --json` | Exit 0, owned #998 row visible; observed 0 | [roadmap-list.txt](roadmap-list.txt). A local ledger projection, not proof of every GitHub issue's current state. |
| [start-task](../../skills/1-hourly/start-task/SKILL.md), lines 281–291: rating preview | Local writer command with dry-run: `python3 utils/py/releases_app.py roadmap rate --gid rmi-01M4D2PN45SNCRZBHASABK3WEC --rated 60/20/50/85 --force --dry-run` | Exit 0, existing rating printed, bytes unchanged; observed 0 | [rating-preview.txt](rating-preview.txt). Deliberate reason: preview these existing scores without replacing them. Both flags are required here; removing dry-run would mutate the row. Removing only force gives the expected exit 3 `already-rated` refusal: [rating-refusal.txt](rating-refusal.txt). Preserve any operator override on a real re-score. |
| [ROUTER](../../ROUTER.md), line 71: print mode | Read-only: `bash validate.sh --print-mode` | Exit 0, chosen width/reason, no gate; observed 0 | [mode-preview.txt](mode-preview.txt). Describes this host/config only; does not verify suites. |
| [relay-xyz](../../skills/1-hourly/relay-xyz/SKILL.md), locator preconditions | Read-only check: `XYZ_HARNESS="$PWD" bash "$HOME/.codex/skills/relay-xyz/find-harness.sh" --check` | Advisory readiness, exit 0; observed 0 | [locator-check.txt](locator-check.txt). Prerequisite is an existing managed Skills Army deployment. All listed CLIs resolved; branch warning is expected for an owned feature clone. Locator success is not authentication or end-to-end CLI execution proof. |
| [relay-xyz](../../skills/1-hourly/relay-xyz/SKILL.md), lines 438–440: `$TICK info <task>` | Read-only, substitute `bin/tick info RELAY-GH998-PLAN` | Known token has status done, exit 0; observed 0 | [token-info.txt](token-info.txt). Positive token was created by actual plan QA. `bin/tick info GH998-NO-SUCH-TOKEN` gave exit 1/not found: [missing-token-control.txt](missing-token-control.txt). Do not substitute nonexistent `tick status`. |
| [start-task](../../skills/1-hourly/start-task/SKILL.md), issue-first intake | External mutation: missing-issue creation via `gh issue create …`; fragments require repo/title/body decisions | Classified, not replayed for this audit | #998's authorized creation was task intake, not a harmless documentation example. No arbitrary fenced commands, installs, or historical embedded instructions were run. |

No demonstrated stale source command required a skill-doc edit. The force requirement was already documented in start-task; the new plan needed the explicit rated-row substitution. This limited sample is not a repo-wide command-certification claim.

## Retained real-work action sequence

Required steps for this assessment: identify the phase/task; distinguish builder statements, reviewer verdict and driver-owned attestation; inspect advance-gate evidence separately; state the limits of real-advisor execution. Prohibited inference/actions: treating an Approved header as gate green, treating absent logs as a pass, merging different task attempts by phase name, running old embedded commands, or claiming approvals from telemetry alone.

| Observed record | What it supports | What remains unknown |
|---|---|---|
| [GH-648 p5 relay](../../marathon-system/gh648-headless-turn-timeout--p5/RELAY.md), lines 87–97 | Builder block records the diagnostic change, stubbed focused checks and a real-advisor launcher probe that failed at startup. It explicitly states scratch receipts were ephemeral and the full real-consult acceptance was incomplete. | Actual token claim/release calls, full consult startup and tool arguments are not independently reconstructed from a token stream here. The builder's test statements are historical claims, not fresh gate receipts. |
| Same p5 relay, lines 100–117 | Reviewer Approved followed in file order by driver attestation for `MARATHON-P5-TURN-R2`, reviewed-head `63e9cf0a7ba11360826dfd2226d28a499bf2bfef`, timestamp 2026-09-18T01:14:16Z. Current canonical review-byte digest check matches the trailer. | The original authoritative `.git/relay-attest` record, terminal result receipt and this candidate's gate log were not retained in these selected files. A matching textual trailer alone is not current resume/merge authority. |
| [GH-648 p3 escalation](../../marathon-system/gh648-headless-turn-timeout--p3/ESCALATION.md), lines 3–10 | `MARATHON-P3-TURN` records relay exit 0, `pre-advance-failed`, `gate: red`, and turn-log unavailable: a negative witness against equating relay exit 0 with safe advancement. | Escalation has no timestamp or detailed failed-suite log. The [p3 approved relay](../../marathon-system/gh648-headless-turn-timeout--p3/RELAY.md) attests a different task, `MARATHON-P3-TURN-R4`. Do not claim this stale escalation and the R4 attestation are one attempt or prove their chronological relationship. |
| p3 approved relay, lines 87–117 | A separately retained R4 builder/reviewer sequence and attestation at 2026-09-18T00:23:48Z; current canonical review-byte digest also matches. | This does not establish all campaign phases or external effects completed. |

This is a successful **review/attestation path** and a separate existing **advance-gate failure path**, not a complete event trace. Documented round labels are retained facts; elapsed-time or round-efficiency scoring is unsupported by these selected records. Prohibited tool behavior remains **unknown**, not silently passed.

### Manual integrity check and red control

[historical-digest-check.txt](historical-digest-check.txt) retains the current results. Use Forge's existing canonicalization; raw file offsets are not the attestation contract. Reproduce from the clone root without writes or historical execution:

```python
from pathlib import Path
import hashlib, re, sys
sys.path.insert(0, "utils/py")
from relay_attest import canonical_bytes
for phase in ("p3", "p5"):
    p = Path(f"marathon-system/gh648-headless-turn-timeout--{phase}/RELAY.md")
    raw = p.read_bytes()
    m = re.search(rb"added-range: (\d+)\+(\d+)\nadded-sha256: ([0-9a-f]+)", raw)
    start, length = int(m[1]), int(m[2])
    review = canonical_bytes(raw)[start:start + length]
    expected = m[3].decode()
    print(phase, hashlib.sha256(review).hexdigest() == expected,
          hashlib.sha256(review + b"X").hexdigest() == expected)
```

Run Python with `PYTHONDONTWRITEBYTECODE=1`. Expected and observed: `p3 True False`, `p5 True False`. The in-memory change is a digest negative control, not a replay of the runtime refusal path or proof of attestation authenticity. No source, fixture or old receipt was edited.

### Structured reporting witness, kept separate

GH-862's [practice README](../2026-09-27+GH-862/practice/README.md) and JSON records provide a clearer bounded negative/positive pair: [run 1](../2026-09-27+GH-862/practice/practice-run-1-search.json) records `same_issue: false`, result created; [run 4](../2026-09-27+GH-862/practice/practice-run-4-record.json) records `same_issue: true`, result updated, `open_matches: []`, one delta comment. These are retained structured observations of issue dedupe, not a marathon, live GitHub validation, or a full tool trace. No practice-posting script was run.

## Decisions and smallest follow-on

- **Adopt:** manual, source-pinned command classification and expected-versus-observed trajectory notes using existing evidence files. This batch supplies both, with deliberate skips and unknowns.
- **Reuse:** current token inspection, rating refusal/dry-run, review canonicalization and separate gate boundary. No new evaluation framework is justified by this sample.
- **Defer:** automated tool-call/approval compliance scoring. This marathon subset lacks a full token/tool stream and terminal gate/result records; a scorer would otherwise award invented passes.
- **Smallest next step:** use the separately requested Storyline/Kanban consolidation effort to choose one real task with its existing complete record set and add missing cross-links, preserving attempt identity. Do not infer joins solely from phase names. #996 comment items 3–4 (reporting/limit display) remain separate unimplemented candidates; this report neither approves nor rejects those runtime changes.

## Verification and limits

Current positive probes and expected refusals passed as recorded. No new registered test, fixture, eval schema or runtime behavior was added. Matching Codex-shim prerequisites passed 43/43 in a disposable full clone; its full raw console log was not captured, so this is a supporting session observation, not an independent retained suite receipt.

Plan QA passed on its second bounded Codex relay round; see [plan relay](../../relay-system/2026-10-07/gh998-plan.md). Deterministic PDDA, diff classification, RELEASES check and final QA results are recorded alongside this report as they complete. Offline issue-sync warnings mean global issue-state reconciliation was not verified by an offline run. A docs-route local gate is not hosted qualification or merge approval.
