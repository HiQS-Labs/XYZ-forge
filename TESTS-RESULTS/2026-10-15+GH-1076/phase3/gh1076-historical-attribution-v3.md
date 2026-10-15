# GH1076 historical attribution — version 3

**The skills-army-hq candidate now has concrete historical support for a bounded pilot assessment.** Two naturally occurring, genuinely mapped-only Medium landings each received a complete full run with one pending member and 409/409 PASS. A separate complete six-member GH988/GH989 payload union received Small PASS while omitting gh620; the later natural full failure has identical relevant payload/publisher/test inputs. This supports the existing consumer mapping correction. It does not by itself certify reduced qualification, coverage completeness, or projected savings.

Versions 1 and 2 remain unchanged. This study used read-only git objects, committed receipts/telemetry and four additional original workflow logs (approximately 6.2 MB). It executed no suites, added no CI cases, triggered/reran no workflow, and made no implementation-owner source writes. Policy membership below is pinned to `f974fcee15647aae6551fcc81b129f5a6127120b`; the proposed package-text-to-area behavior is identified as a proposal, not attributed to that historical policy.

## Exact naturally successful eligible full snapshots

| Original run | Actual tested snapshot and complete pending identity | Exact changed scope | Existing evidence |
| --- | --- | --- | --- |
| [38346799359](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/38346799359) | `ecbe7722f0018ff50f3298c61441457e7520c776`; only PR1047; outer log line461 explicitly says one landing, full, tier2 | Twelve paths: skills-army-hq `intake.py`, `sync.py`, `SKILL.md`, plus project/relay/evidence/ledger records. No test, gate, unknown code or second area. | Full409/409 PASS; committed receipt identifies only PR1047 at exactly this tested/landing SHA. All five skills-army focused suites and all72Small literal suite names appear with rc0 in original telemetry. |
| [38313598719](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/38313598719) | `489ba1b45b6924dbb57f70ba1bed98645db54644`; only PR1035; outer log line422 explicitly says one landing, full, tier2 | Eighty-four paths, mostly evidence: implementation changes are skills-army-hq `intake.py` and mapped `utils/py/xyz_mini_sync.py`; other changes are prose/evidence/ledger. `mini/ADAPTATIONS.md` adds an explanation of existing adapted-root ownership markers. No test/gate/unknown implementation change. | Full409/409 PASS; committed receipt identifies only PR1035 at exactly this tested/landing SHA. Same77candidate literal shell suite names all appear with rc0. |

For both, the receipt telemetry digest matches the committed telemetry bytes. Every pending landing is an ancestor of its tested snapshot. Exact first-parent merge diffs, complete member identities and telemetry line numbers are in the companion JSON. These are complete historical scopes, not conclusions drawn from the triggering PR title or an API file list capped at100files.

The posthoc Small+skills-army union contains77literal shell suite names at the pinned policy source. That membership comparison is not a reduced run: no reduced gate was executed, receipt produced, or walltime measured. Separate Python/doc stages and runner behavior still need their own exact contract. Full-suite success means the original full job passed; it is not a new empirical catch-rate denominator.

## Reconstructed GH988/GH989 pending union and the inherited failure

[Run37700855208](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/37700855208) has original outer log line407: **six pending landings**, tested `a48fa48fd45e0ebae6c64f50651f58534b0d872d`, `validate.sh --sequential --subsystem small`, tier1. Its committed receipt pack has exactly the same six identities:

| Member SHA | Role |
| --- | --- |
| `db85c19984f2b4bdcadb287e736ecd78b1815851` | GH988 adds `skills/3-weekly/skills-army-hq/bot-monitor-prompt.md` |
| `35bb4037b0738201600ee492f5fc5a249482626c` | GH988 express ledger shipment |
| `42d5bf65231bf90b7549bff86ea509f2aafb1cf9` | GH988 reconciliation |
| `59b0e386b771c830b26d383040be205dec7bffd2` | GH989 renames the payload to `BOT-DAILY-HEALTH-CHECK.md` |
| `e427db63162946edb773e06068741d01409979f0` | GH989 express ledger shipment |
| `a48fa48fd45e0ebae6c64f50651f58534b0d872d` | GH989 reconciliation |

The full union contains nine changed path names: the package Markdown add/rename plus governance/ledger/project records. It contains no unrelated code, tests or gates. Under the proposed package-text consumer correction, this is one mapped skills-army area; under the historical policy it was Small. The historical Small job passed75/75, with72literal Small suite names in telemetry and none of the five skills-army focused suites.

Later [natural full run37723297290](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/37723297290) tested `e0c0bc9172d56efe54fd62f1afb44d90a18b4b8c`, with exactly one pending PR992 (outer log line34), full tier3. Its gh620 section records26PASS/2FAIL:

- Line7517: the actual payload contains unexpected `BOT-DAILY-HEALTH-CHECK.md`.
- Line7518: the manifest no longer matches the pinned nine-payload expectation.
- Driver summary line14980 identifies `gh620-skills-army-mini-sync.sh` as failed.

This is the already attributed GH995 stale payload-contract expectation, not a newly discovered runtime product defect or a new Medium regression count. PR992 itself contains full-surface merge-cleanup guidance/stop-hook changes and inherited the package discrepancy.

**The relevant inputs are provably identical between earlier Small-tested a48 and later full-failed e0:** git tree/blob identities match for the entire canonical skills-army package, `utils/py/xyz_mini_sync.py`, existing gh620 suite, fixture guard, both licenses and mini skills-army gitignore. The diff across that entire scoped set is empty. The publisher expands every tracked package file; the existing gh620 expected set omitted the new file. Therefore the earlier Small-qualified snapshot already contained the exact payload/expectation inputs responsible for the later observed failure. The proposed area/consumer selection includes that existing gh620 suite, whereas Small omitted it.

This is a source-equivalence inference about that explicit literal payload assertion. It is **not** a full run at a48, whole-repository/history equivalence, environment equivalence, or permission to backdate qualification. No naturally occurring full-red run at a48 was found or invented.

## Complete successful recovery union, including the mapped GH993 member

[Run37729005966](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/37729005966), outer log line439, qualified **seven pending members**, tested `f44edf4ef33a266cdfa34761d1671ce5c10956a7`, full tier3,410/410 PASS. The seven committed receipt identities are:

1. PR992 at `e0c0bc9172d56efe54fd62f1afb44d90a18b4b8c`.
2. GH993 implementation `f48a08a511bccb6baddb5f598614e7dc4c309043` — only skills-army `SKILL.md`, `intake.py`, `sync.py`.
3. GH993 ledger shipment `d822996cc083e1775501703302736184fe64d8de`.
4. GH993 reconciliation `18b07225eae0c20133fa9307bd95cba1bd16e54a`.
5. GH995 existing-test expectation correction `dc4dd65d1cad5e81ac9b5af2a97fa80530630741`.
6. GH995 ledger shipment `b9b284fafda3afde845d4162b7f4a50e10e9dfb1`.
7. GH995 reconciliation `f44edf4ef33a266cdfa34761d1671ce5c10956a7`.

All seven identities and their45-path union are reconstructed, receipt digest verified, and original outer count matched. The GH993 code member is a useful mapped-area positive, but **this complete recovery union is Large**, because it includes PR992 and the test-only correction. It must not be counted as an independent reduced-Medium proof or as seven independent full runs.

## Bounded assessment and precise remaining artifact

This research removes two generic objections: eligible naturally full-tested mapped-only snapshots do exist, and the relevant GH988/GH989 pending union can be reconstructed completely. The package-consumer gap also has stronger support than a title-based anecdote: the omitted consumer's known failing literal inputs are byte/tree-identical across the Small and failed-full snapshots.

The actionable candidate is a **skills-army-hq-only** pilot using Small plus the existing five area/consumer suites. Package text needs that area classification because it ships as machine input. Keep global/safety/unknown/test-only/multi-area changes full. Do not extrapolate to other areas, arbitrary shell selection, or stale receipt reuse.

The minimum remaining implementation/approval artifact is a reviewed, frozen contract tying exact base/member/tested SHA, policy selection, existing consumer suites, environment/runner/receipt identity and rollback to the proposed gate, accompanied by the current exact-base full-versus-proposed existing-check evidence. The parent’s active benchmarks/reviews can supply that current evidence; historical results cannot substitute for it. Workflow/protection compatibility and normal review remain required. No new CI case approval is implied.

If policy demands a **naturally full-red, entirely mapped-only qualification at the exact historical payload snapshot**, that specific artifact is unavailable in the inspected history: the exact earlier job was Small, and the natural full-red appeared later under inherited Large PR992. That is the precise unavailable historical artifact, rather than an unspecified claim that nothing can proceed. The existing source-equivalent counterexample and two complete Medium positives should be evaluated explicitly when deciding whether they sufficiently support a bounded pilot.

Companion `gh1076-historical-attribution-v3.json` retains exact member ranges, unions, original log hashes/lines, receipt/telemetry hashes, full summaries, candidate membership and all causal limits. No issue/comment posted by this research lane.
