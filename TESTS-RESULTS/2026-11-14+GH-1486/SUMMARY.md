# GH-1486 evidence — `/re-vendor-xyz`

Candidate `7366dd522` (skill, pointers, changelog, final-QA round-1 fixes). Base `5967bde25`. The A3–A6 driver was re-run on `7366dd522`; the text checks, the full suite set, the step-9 smoke and the docs gate below were run on `eb9a48126` (the round-1 fixes changed only `SKILL.md` prose, the block's last line and the vendor-stack example; link suites re-run green on `7366dd522`). No new test suite or registry entry (GH-831); everything below is a manual check or an existing suite. Machine paths are redacted to `<repos>`, `~` and `<fixture>`.

| Check | What it observes | Result | Log |
|---|---|---|---|
| A3–A6 fixture driver | Runs the skill's steps 1–8 block **extracted verbatim from `SKILL.md`** against fixture targets (private registry, backup folder, no collection) | 55 passed, 0 failed | `candidate-A3-A6.log`, driver `fixture-checks.sh.txt` |
| Base red controls | Same driver and the A1/A2/A7 probes on `5967bde25` | driver cannot find the skill block (fail); `ls` and both `git grep` probes find nothing | `base-red-controls.log` |
| A1, A2, A7 text | Frontmatter name and triggers, closed stop list and three-part current test in the skill, three pointers | all present | `a1-a2-a7-text.log` |
| Regression suites | `gh589-skill-viewer`, `path-integrity`, `gh660-skill-drift`, `gh312-vendor-preserves-state`, `gh293-vendored-guard-drift`, run in the disposable verify clone with an identity bracket | 8/0, 3/0, 7/0, 14/0, 15/0 | `regression-suites.log` |
| Smoke, step 9 | The skill's step 9 block as written, against this machine's real Skills Army collection, read-only | rc 0, `drifted 0`, collection unchanged | `smoke-step9.log` |
| vendor-stack example | The corrected step 1 snippet from `vendor-stack/SKILL.md`, extracted and run from a subfolder of the verify clone | rc 0; `HARNESS` and `PDDA` resolve to the checkout top | `vendor-stack-snippet.log` |
| Docs gate | `utils/ci-route.sh` route, then `utils/pdda/pdda.sh run` | `docs_only=true`, tier 1; no errors (698 repo-wide warnings; the two about GH-1486 say issue state was unavailable offline) | `pdda-run-summary.log` |

What each A4 case proves: the named `re-vendor-xyz: stopped:` line appears, no backup zip is made, `xyz-sync.sh update` is never invoked (the block prints `re-vendor-xyz: running:` immediately before calling it), and `.xyz/VERSION` is byte-identical. The bare-command contrasts (no-op exit 0 for an unregistered target; vendoring from a dirty source and from an unpublished commit) are recorded beside them to show what the skill prevents; they are not the safety proof.

Main path is A3 (stale copy refreshed and verified on all three conditions); the adjacent real-world path is A6 (rerun on a current copy: "already current", no backup, no update). A5 shows a copy that `check` reports `ok` plus `SAFETY GUARD MISSING` is refreshed rather than accepted.

Not exercised: a real consumer repository (refreshing one would write outside this task), and the hand-off into `/skills-army-hq` apply (no Forge skill was drifted on this machine at the time of the read).
