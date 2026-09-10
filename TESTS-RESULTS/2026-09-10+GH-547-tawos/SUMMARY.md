# GH-547 TAWOS Task A qualification result

## Verdict

**TAWOS qualifies as a large source-domain corpus for a narrow bug-versus-feature transfer experiment, but it fails the frozen gate for Needle's eight-purpose classifier. Do not proceed directly to eight-class ModernBERT training.**

The archive and relational structure passed integrity checks. Conservative purpose mapping covers 375,118 of 458,232 issues (81.86%), but the apparent breadth is misleading: 374,044 mapped examples are only `bug_fix` or `feature_enhancement`. `research_evaluation` has 22 examples and `testing_validation` 353, below the predeclared 500-example floor. `maintenance`, `planning_design`, and `merge_closeout` have no conservatively mapped native type. Label precision also remains unmeasured pending independent adjudication of the frozen sample.

## Corpus evidence

- Archive MD5 matched the publisher value: `e9c5ecc7649d55f0cf2fb4efb5664494`.
- Imported counts: 458,232 issues, 39 projects, 2,001 components, 366,922 issue-component links, and 9,253,419 change-log rows.
- Orphan checks for issue→project and issue-component relations both returned zero.
- Dates span February 2002 through October 2020. This supports project/time grouping inside TAWOS but creates material age and Jira-to-GitHub domain shift relative to current HiQS work.
- Component cardinality: 137,241 issues (29.95%) have no component; 282,029 (61.54%) have one; 38,962 (8.50%) have multiple, with a maximum of 32. Components remain project-local auxiliary metadata and are not HiQS labels.

## Conservative purpose mapping

| HiQS purpose | TAWOS examples | Gate |
|---|---:|---|
| `bug_fix` | 217,417 | passes volume |
| `feature_enhancement` | 156,627 | passes volume |
| `documentation` | 699 | passes volume narrowly |
| `testing_validation` | 353 | fails 500 floor |
| `research_evaluation` | 22 | fails 500 floor |
| `maintenance` | 0 | unsupported |
| `planning_design` | 0 | unsupported |
| `merge_closeout` | 0 | unsupported |

The 83,114 conservatively unsupported issues are chiefly Story (31,394), Task (28,338), Sub-task (14,396), Epic (4,157), Support Request (2,368), Question (1,396), and Technical task (987). Automatically mapping these to planning or research would confuse workflow containers with the semantic kind of work. Resolution was not used as a purpose label because it is post-issue lifecycle information and would leak outcomes into an intake classifier.

## Context-length evidence

The deterministic cross-project/type sample contains 429 issues, capped at two per observed `(project, native type)` stratum. It had median 66, p95 327, p99 601, and maximum 2,491 ModernBERT tokens; none exceeded 8,192, so the frozen representative-sample token gate passed.

The longest-100 stress sample tells the required tail story: all 100 exceed 8,192 tokens, ranging from 10,683 to 492,782 tokens. Across the full corpus, 453,601 issues have at most 4,096 characters, 3,795 have 4,097–16,384, 606 have 16,385–32,768, and 230 exceed 32,768. A future training pipeline therefore needs an explicit truncation/window policy even though typical records are short.

## Gate results

| Gate | Result |
|---|---|
| Archive/schema/row-count integrity | PASS |
| Representative-sample token overflow below 1% | PASS (0/429) |
| Conservative aggregate mapping coverage at least 70% | PASS (81.86%) |
| Every mapped class has at least 500 examples | **FAIL** |
| Independent label-quality review | **PENDING** |

The predeclared stop rule applies: no eight-class training was run.

## Recommended continuation

1. Independently adjudicate the frozen 429-record local review manifest; its SHA-256 is `be381ff7a1b38ade5f2f2eb51926e2eab88e9b22029d979a830fd7e414d9b31f` and raw public text remains local only.
2. If bug/feature precision is acceptable, run a deliberately narrow transfer test: TAWOS bug/feature source training, then HiQS target fine-tuning/evaluation using a fresh untouched HiQS holdout and the same TF-IDF baseline.
3. Do not use TAWOS to fill the other six purposes. Those classes need HiQS-derived or separately qualified data.
4. Keep component classification as a separate HiQS-only task.

## Runtime and scope

The SQL archive imported into a temporary socket-only MySQL instance with networking disabled. Full aggregation and tokenizer analysis completed in 29.6 seconds after import. No model weights were trained, no network service was exposed, and no raw issue text was committed. The cache contains the public archive, temporary database, and private review manifest; it is retained for the next adjudication/transfer decision.
