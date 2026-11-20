# Relay: GH-1535 (KS-02) Plan QA — Decide Hold Release & U15 Body/Label Holds

NEXT: Producer
ROUND: 2 / 3
STATUS: Approved
PRODUCER: antigravity
REVIEWER: codex
ARTIFACT: PROJECT/2-WORKING/GH-1535-KS02-DECIDE-HOLDS.md

## Context
Plan QA for GH-1535 (KS-02, refs #1541 v5 KS-02 + U15 + KS-11c): operator decision comment release (`Operator decision` / `Operator decision: close` / `Operator decision: hold` supersession by `--owner`), preventing released issues from falling into rule 9 (`unclassified`), and U15 body/label holds (`status:held`, `HELD:`, `Blocked by #N`, `after #N`) across all issue types in `skills/1-hourly/kickstart/scripts/build_queue.py` + `skills/1-hourly/kickstart/SKILL.md`.

## Review prompt
Review `PROJECT/2-WORKING/GH-1535-KS02-DECIDE-HOLDS.md` against `#1535`, `#1541` v5 KS-02 (including U15 & KS-11c), `skills/1-hourly/kickstart/scripts/build_queue.py`, `skills/1-hourly/kickstart/SKILL.md`, and `PROJECT/PDDA.md`.
Check:
1. Are all KS-02, U15, and KS-11c requirements satisfied (owner-only comment release, `Operator decision` vs `Operator decision: close` vs superseding `Operator decision: hold`, never falling into rule 9, PR `#1526` keeping `closes #1518`, and `status:held` / `HELD:` / `Blocked by #N` / `after #N` across all issue types)?
2. Are false-positive guards (fenced/inline backticks, closed past-tense `after #N`) safe and fail-closed without missing real body holds?
3. Is the verification plan discriminating (red pre-change, green changed), honest, PDDA-compliant, and free of new test suites (GH-831)?

End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis, set `STATUS: Approved` only on PASS, and flip `NEXT: Producer`.

## Log

### Round 1 — codex (Reviewer)

**[Major] Preserve formatted references inside real prose holds (plan lines 35–41).** Blanket removal of inline backtick spans deletes the dependency in ordinary prose such as `Blocked by ` followed by a backticked `#1499`, or `Only after ` followed by a backticked `#1499` and ` lands`. Neither remaining prose string matches the specified dependency regex. A bug issue can therefore enter E and its closing PR can enter A despite an explicit active body hold. This contradicts U15's fail-closed promise. Distinguish a wholly quoted example marker from prose containing a code-formatted reference; specify the intended treatment before implementation. Keep the existing wholly quoted `HELD:` example negative control and add a paired manual check for a real prose hold with a formatted reference, including parked-PR propagation. No new suite is needed.

Narrow design probe (not an execution of a future implementation), command:

```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 - <<'PYPROBE'
import re
for body in ["Blocked by `#1499`", "Only after `#1499` lands", "`HELD: example only`"]:
    cleaned = re.sub(r"`[^`]*`", "", body)
    match = re.search(r"\b(?:blocked\s+by|after)\s+(?:PR\s+)?#(\d+)\b", cleaned, re.I)
    print(f"{body!r} -> {cleaned!r}; dependency_match={bool(match)}")
PYPROBE
```

Exit: `0`. Decisive output:

```text
'Blocked by `#1499`' -> 'Blocked by '; dependency_match=False
'Only after `#1499` lands' -> 'Only after  lands'; dependency_match=False
'`HELD: example only`' -> ''; dependency_match=False
```

**Verification refinement:** The proposed active-clause fallback for a reference absent from `open_refs` has no positive control: the only `after` positive case names an open PR. Add one absent-reference active clause and retain the closed past-tense negative. Also check that an owner proceed/close comment cannot override an independent body/label hold. These are bounded manual cases in the already planned evidence, not new gate machinery.

**Basis:** Swept the complete plan, current `build_queue.py` (including `main` → parking → PR classification → issue classification → render), the kickstart rule-list mirror, and PDDA. The owner-only latest-decision design, dedicated close path, proceed fallback, parking before folding, and paired base/candidate evidence are otherwise sound at plan level. Verification is still prospective; no implementation or gate pass is claimed. No phase gate was configured in this relay and none was run. Reversibility: Easy for the plan correction; the relevant failure mode is dispatching or closing an explicitly held issue.

Graph evidence: Verify-tier attempt against `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-11-18T19:39:07Z`; bounded build_queue search returned zero nodes with no more pages. Coverage reports missing freshness metadata for the newer plan and kickstart files. Read the local files directly; do not treat the older graph as completeness evidence. Live GitHub issue queries were attempted; subsequent focused reads of #1535 and #1541 failed with `error connecting to api.github.com`, so exact live v5 reconciliation remains unverified. The finding above follows directly from the local plan's stated U15 contract and does not depend on that unavailable comparison.

swept file: yes
VERDICT: FAIL

STATUS remains Open. NEXT is Producer for correction and adjudication.

### Round 1 — codex (Reviewer, repeat assessment of seeded artifact)

**Block — [Major] The prior formatted-reference finding remains unresolved.** The artifact still explicitly removes all inline backtick spans before dependency matching (line 35), with unchanged matching rules at lines 39–40. Thus ordinary prose `Blocked by ` followed by a backticked `#1499`, or `Only after ` followed by a backticked `#1499` and ` lands`, loses the reference and can queue a held bug and its closing PR. The exact design probe, exit status and decisive output are retained in the preceding review; this turn did not rerun it or execute implementation fixtures. Preserve formatted reference tokens in real prose while excluding wholly quoted examples, and specify paired manual controls including closing-PR parking. The absent-reference active-clause and independent-hold-versus-owner-release controls requested above are also still absent from the verification plan. No producer adjudication or correction is present in this seeded thread.

**Basis:** Swept the complete seeded plan and current build_queue source, including parking → PR classification → issue classification → render, and checked the kickstart ordering mirror and PDDA contract. Owner-only latest-decision parsing, close/proceed routing before unclassified, and keeping PR #1526's closing reference are otherwise suitable plan-level choices. Paired manual evidence with provenance rather than a new suite is proportionate. Reversibility: Easy for the requested plan correction; the consequence of leaving it unresolved is dispatching an explicitly held issue.

Live read-only `gh issue view 1535 --repo HiQS-Labs/XYZ-forge --json body,comments` returned exit 0 and confirmed the #1518/#1526 replay requirement. The equivalent #1541 read returned exit 0 and confirmed v5 KS-02/U15's owner-only release, close bucket, rule-9 protection and body/label holds. A subsequent focused KS-11 read failed with `error connecting to api.github.com`; full exact live KS-11c reconciliation remains unverified. This does not affect the directly evidenced plan defect above. No gate is configured in this thread, and no gate, suite or fixture was run; approval cannot rely on a later gate.

Graph: Verify-tier discovery used `Users-noelsaw-Documents-GH-Repos-XYZ-forge`; build_queue search returned 0 results, `has_more: false`. Coverage generation `2026-11-18T19:39:07Z` reports missing freshness for the plan, build_queue and kickstart skill. Used direct local source fallback for those paths; no completeness claim rests on the graph.

swept file: yes
VERDICT: FAIL

STATUS remains Open. NEXT: Producer (antigravity), for correction and adjudication.

### Round 2 — antigravity (Producer)

Addressed the Round 1 `[Major]` finding and all verification refinements in `PROJECT/2-WORKING/GH-1535-KS02-DECIDE-HOLDS.md`:

1. **[Resolved] Preserve code-formatted issue references inside real prose holds:** Replaced blanket inline-backtick stripping with a three-step sanitization: strip fenced code blocks, unwrap reference-only backtick spans (`re.sub(r"`((?:PR\s+)?#\d+)`", r"\1", cleaned, flags=re.I)`), then strip remaining single-line inline backtick spans (`re.sub(r"`[^`\n]*`", "", cleaned)`). This matches ``Blocked by `#1499` `` and ``Only after `#1499` lands`` while still ignoring wholly quoted examples like `` `HELD: owner decision required` `` and `` `Blocked by #1499` ``.
2. **[Resolved] Added requested verification controls:**
   - Paired pre-change/changed controls for formatted-reference prose holds (``Blocked by `#1499` ``, ``Only after `#1499` lands``) including closing-PR parking propagation.
   - Absent-reference active-clause positive control (`Only after #9999 lands` where `#9999` is absent from `open_refs`) alongside the closed past-tense negative (`after #1403 passed`).
   - Independent body/label hold non-override control (`status:held` / `HELD:` stays held even when an `--owner` `Operator decision` proceed/close comment exists).

Ready for Round 2 review. End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis, set `STATUS: Approved` on PASS, and flip `NEXT: Producer`.

### Round 2 — codex (Reviewer)

**Ship — plan approved.** The Round 1 formatted-reference finding is resolved: reference-only inline spans are unwrapped before remaining inline examples are removed. The plan now includes formatted prose positives with closing-PR parking, an absent-reference active-clause positive, the closed past-tense negative, and independent body/label holds surviving owner proceed/close comments. No remaining blocking plan defect found.

**Basis:** Swept the complete revised artifact, current `build_queue.py` through main → parked issues → PR classification → folding → issue classification → render, the kickstart ordering mirror, and PDDA. The design extends the existing classifier, preserves other-session ownership, checks independent holds before folding/release, uses latest owner-only first-line decisions, routes close explicitly and guarantees a proceed fallback. PR #1526 retains its closing reference rather than weakening the relationship to #1518. The retained paired base/candidate procedure and provenance are suitable prospective verification without a new suite. Reversibility: Easy for this plan; implementation correctness and final verification remain outstanding.

A narrow design probe of the exact three sanitization substitutions ran with `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR="$PWD/.relay-scratch/tmp"` (not an implementation fixture or gate):

```python
import re
for body in ["Blocked by `#1499`", "Only after `#1499` lands", "`HELD: example only`", "`Blocked by #1499`"]:
    cleaned = re.sub(r"```.*?```", "", body, flags=re.S)
    cleaned = re.sub(r"`((?:PR\s+)?#\d+)`", r"\1", cleaned, flags=re.I)
    cleaned = re.sub(r"`[^`\n]*`", "", cleaned)
    print(repr(body), "->", repr(cleaned))
```

Command: `python3 - <<'PY'` with the above body and terminating `PY`. Exit `0`; decisive output:

```text
'Blocked by `#1499`' -> 'Blocked by #1499'
'Only after `#1499` lands' -> 'Only after #1499 lands'
'`HELD: example only`' -> ''
'`Blocked by #1499`' -> ''
```

Verify-tier graph discovery used `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation `2026-11-18T19:39:07Z`. Bounded build_queue search returned zero nodes (`has_more: false`); coverage reports missing freshness for the plan and kickstart files, so direct local source reads supply the evidence. No graph completeness claim is made. Live #1535/#1541 queries were attempted; the broad #1541 read returned content, but focused exact-body re-reads failed with `error connecting to api.github.com` and produced an empty scratch artifact, rejected as evidence. Exact current live KS-11c reconciliation is therefore limited to the requirements already retained in this thread and the local plan; it is not claimed independently reverified. No phase gate is configured; none was run or assumed. This approves the implementation plan only, not implementation or merge readiness.

swept file: yes
VERDICT: PASS

STATUS: Approved. NEXT: Producer (antigravity).


### Attestation · relay-drive — 2026-11-20T08:07:33Z
task: RELAY-PLAN
reviewer: codex
status: Approved
reviewed-head: 44f9f960eff4ef3ffa531f9e1af0a25d0bd297e1
added-range: 9324+2991
added-sha256: e26d0bbe339e97f8955c480761ee5771698cc596684e174a311def10232e2609
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
