# Marathon preflight packet — gh-1295-injected-text-in-briefs

- Generated: 2026-11-08T08:35:35Z
- Mode: gh-bundle
- Sources: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/PROJECT/2-WORKING/GH-1295-INJECTED-TEXT-IN-BRIEFS.md 
- Target root: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner (development @ 153163bd0)
- Suggested branch: `marathon/gh-1295-injected-text-in-briefs-2026-11-08` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `python3 -m pytest test/test_python_layer.py && bash test/synthetic/gh94-containment-invariants.sh`

- Artifacts: utils/py/harness.py,test/gh174-harness-registry.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1902 LOC across 2 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh174-harness-registry.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/PROJECT/2-WORKING/GH-1295-INJECTED-TEXT-IN-BRIEFS.md` (6 checkbox(es) found across the WHOLE document — the doc has no `## Acceptance` section, so this list may include phase checklists). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #1295 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] Inspect `_sections` and `render_brief` in `utils/py/harness.py`.
- [ ] Evaluate fencing options: wrap sourced scope in explicit Markdown code fence or quote block with untrusted data disclaimer.
- [ ] Evaluate pattern filter for common override strings (`IGNORE ALL PREVIOUS INSTRUCTIONS`, `SYSTEM OVERRIDE`).
- [ ] Sourced issue body instructions cannot be read as instructions by builder prompts in generated briefs.
- [ ] Normal issue bodies render unchanged without regression.
- [ ] No new test files (GH-831).
  "target": { "repo": ".", "ref": "development" },
  "gate": "python3 -m pytest test/test_python_layer.py && bash test/synthetic/gh94-containment-invariants.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/py/harness.py", "pattern": "untrusted_issue_text|sanitize_brief_scope",
      "note": "pre-fix: harness.py does not fence untrusted scope text in briefs" }
  ],
  "artifacts": [ "utils/py/harness.py" ],
  "remediation": {
    "source": "issue#1295",
    "criteria": "Render sourced issue scope inside explicit untrusted fences or hold brief when instruction patterns match; no new tests (GH-831)."
  }

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/harness.py,test/gh174-harness-registry.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `python3 -m pytest test/test_python_layer.py && bash test/synthetic/gh94-containment-invariants.sh`, and NOT `test/gh174-harness-registry.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1295-injected-text-in-briefs RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/py/harness.py,test/gh174-harness-registry.sh \
  --pre-advance-cmd 'python3 -m pytest test/test_python_layer.py && bash test/synthetic/gh94-containment-invariants.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
- `marathon-invocation.json` — the same invocation as structured data (`swarm-preflight/marathon-invocation@1`, GH-280); supervisors consume this, never the shell text
