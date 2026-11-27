---
gh_issue: 1666
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1666
title: "swarm_preflight: acceptance readers split lines like Markdown (CR/LF only)"
status: "Prepared 2026-11-27 (1-INBOX, not enqueued, not started)"
created: 2026-11-27
updated: 2026-11-27
owner: Conveyor preparation (Flywheel Run A queue; ledger #1658)
doc_type: bugfix
ratings_provisional: true
non_goals:
  - "#1665 (deviation split on the first '— reason:'): separate issue, same file, not in this scope"
  - The frozen Bash preflight twin (`utils/swarm-preflight.sh`, GH-308)
  - Contract extraction and other `splitlines()` callers outside the acceptance readers
  - Any change to criterion normalization, headings, fences or continuation rules
  - A new test suite or gate machinery (GH-831)
goal: >
  Issue-side extraction, capture-side extraction, the deviations reader and collect_inline_checklist
  split lines on \r\n, \r and \n only, so a criterion containing U+0085/U+2028/U+2029 is read whole
  and identically on both sides.
---

# GH-1666 · Acceptance readers use the Markdown line model

## Status

| What was just completed | What's next |
|---|---|
| Recon, capture, Preflight Contract, probe proof (unfixed / simulated fix / one-sided fake fix), consumer validation and PRS rating prepared 2026-11-27 at `6142128d9c43`. No implementation, no queue admission. | Preparation review, publication of the Run A preparation PR, merge to `development`, then a fresh preflight at the integration ref (Conveyor step 6). Next owner: the Run A launch step (#1658). |

## Acceptance

<!-- Copied verbatim from the issue, including the U+2028 inside `Alpha…beta` in criterion 2 (that character is this issue's own example). -->

- [ ] Issue extraction, capture extraction and `collect_inline_checklist` split lines on `\r\n`, `\r`, `\n` only.
- [ ] The U+2028 fence-closer input and the `Alpha beta` verbatim copy both read `match`.
- [ ] Covered in the existing `test/gh400-acceptance-fidelity.sh` (no new suite, GH-831).

## Recon note (parent-only)

The operator's brief asked for capture, contract, preflight and one independent review. The parent read the whole seam, so no separate research child was dispatched. Budget: this preparation session; attempts consumed: 0.

- **Baseline:** `origin/development` at `6142128d9c433d6b12972c6cd9a6f864f0ed9da2` (2026-11-27).
- **Observed (reproduced):** with `t = "## Acceptance\n\n- [ ] Alpha\u2028beta\n- [ ] Gamma\n"`, `extract_acceptance_criteria(t)` and `extract_acceptance_criteria(t, plain_bullets=True)` both return `['Alpha', 'Gamma']`, and `collect_inline_checklist(t)` inlines `- [ ] Alpha`: the text after the separator is silently dropped. Same for U+0085 and U+2029. Markdown keeps it as line content (CommonMark §2.1).
- **Fence example:** the issue's U+2028 fence-closer example already reads correctly at this baseline (`['Real']`) because GH-1646 (`ab890c545`) judges fence markers on CR/LF lines (`utils/py/swarm_preflight.py:629-637`). The probe keeps it as a no-regression control.
- **Call path:** `check_acceptance_fidelity` (`:972`) compares `extract_acceptance_criteria(issue, plain_bullets=True)` with `extract_acceptance_criteria(capture)` (`:594`, lines split at `:615`) and `extract_declared_deviations` (`:677`, split at `:689`); the packet inlines `collect_inline_checklist` (`:827`, split at `:843`).
- **State writer / consumer:** none written; the readers feed Preflight's acceptance-fidelity verdict and the packet's inlined checklist.
- **Smallest plan:** one shared CR/LF line split used by all three readers (and the marker-line alignment in `extract_acceptance_criteria` simplified to it). The issue explains why all readers must move together.
- **Dependencies / overlap:** no open PR touches `swarm_preflight.py`. #1665 edits `extract_declared_deviations` in the same file (separate issue, not queued here). #1580 stays open for other preflight scope; its landed PR #1593 is in this baseline.
- **Discriminating check:** the fix probe (contract below) exits 0 only when, for each of U+0085/U+2028/U+2029, the issue side and capture side return the same two criteria with `Alpha…beta` whole, the inlined checklist keeps `beta`, the fence control stays `['Real']`, and a CR/LF/CRLF control still splits into three. Matrix (`TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/`): base 1; simulated fix 0; one-sided fake fix (issue side only) 1.
- **Write set:** `swarm_preflight.py`, a case in the existing `test/gh400-acceptance-fidelity.sh`, plus one new delivery receipt (`artifacts_new`, with a `path_absent` probe).
- **Foreseeable approvals/runtime:** none; probe and gate need no network.
- **Unknowns:** none blocking.
- **Next owner:** the Run A launch step (#1658), then Jog.

## Attempt and retry history (read 2026-11-27, nothing reset)

- No `roadmap_items` row, no `jog_queue` row, no capture, no branch or PR for #1666 before this preparation. Attempts consumed: 0.

## Rating rationale

`rated 45/35/50/80` (sum 210), written through `roadmap pickup` on 2026-11-27; `ratings_provisional` stays true until the operator confirms.

- Severity 35: a criterion containing a rare separator is truncated silently on both sides, so fidelity can read `match` on the wrong text.
- Priority 45: found in GH-1646 final QA; not observed on a real issue yet.
- Appeal 50: neutral.
- Effort 80: three readers in one file plus one suite case.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash test/gh400-acceptance-fidelity.sh",
  "round_cap": 9,
  "prepared_commit": "6142128d9c433d6b12972c6cd9a6f864f0ed9da2",
  "artifacts": [
    "utils/py/swarm_preflight.py",
    "test/gh400-acceptance-fidelity.sh",
    "TESTS-RESULTS/2026-11-27+GH-1666/delivery.md"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-11-27+GH-1666/delivery.md"
  ],
  "fix_probes": [
    {
      "type": "command",
      "cmd": "env PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'\nimport sys; sys.path.insert(0, \"utils/py\")\nimport swarm_preflight as s\nfor cp in (0x85, 0x2028, 0x2029):\n    L = chr(cp)\n    t = \"## Acceptance\\n\\n- [ ] Alpha\" + L + \"beta\\n- [ ] Gamma\\n\"\n    i = s.extract_acceptance_criteria(t, plain_bullets=True)\n    c = s.extract_acceptance_criteria(t)\n    k = s.collect_inline_checklist(t)[0]\n    assert i == c and len(i) == 2 and \"Alpha\" in i[0] and \"beta\" in i[0], (hex(cp), i, c)\n    assert len(k) == 2 and \"beta\" in \" \".join([k[0][0], *k[0][1]]), (hex(cp), k)\n    f = \"## Acceptance\\n\\n- [ ] Real\\n\\n~~~\\n~~~\" + L + \"\\n- example output\\n~~~\\n\"\n    assert s.extract_acceptance_criteria(f, plain_bullets=True) == [\"Real\"], (hex(cp), \"fence control\")\nassert s.extract_acceptance_criteria(\"## Acceptance\\n\\n- [ ] A\\r\\n- [ ] B\\r- [ ] C\\n\") == [\"A\", \"B\", \"C\"], \"CR/LF control\"\nPY",
      "expect_nonzero": true
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-11-27+GH-1666/delivery.md"
    }
  ],
  "remediation": {
    "source": "issue#1666",
    "criteria": "extract_acceptance_criteria (both sides), extract_declared_deviations and collect_inline_checklist split lines on \\r\\n, \\r and \\n only; a criterion containing U+0085/U+2028/U+2029 is read whole and identically on both sides, fences and CR/LF behave as today. Add one case to test/gh400-acceptance-fidelity.sh. Record the probe's before/after output in TESTS-RESULTS/2026-11-27+GH-1666/delivery.md. Leave the frozen Bash twin and #1665 alone. No new suite."
  }
}
```

The probe is an inline manual check, not a suite: it exits 0 only when the fixed behavior and all controls hold, and `expect_nonzero: true` makes any crash read as unfixed. It is inline so it evaluates at `prepared_commit` itself. A readable copy and its red/green outputs are in `TESTS-RESULTS/2026-11-27+GH-1658-runA-prep/`.
