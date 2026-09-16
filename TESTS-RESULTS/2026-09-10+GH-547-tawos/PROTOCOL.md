# GH-547 TAWOS Task A qualification round

## Objective

Determine whether TAWOS 1.1 is suitable source-domain data for Needle's ModernBERT work-purpose classifier. This round measures corpus integrity, native distributions, conservative purpose-label coverage, component behavior, temporal/project split support, and ModernBERT token lengths. It does not train a model or map TAWOS components into HiQS component labels.

## Pinned input

- Figshare article: `21308124`, version 1
- Archive file: `TAWOS.sql.zip`, 637,550,449 bytes
- Publisher MD5: `e9c5ecc7649d55f0cf2fb4efb5664494`
- Archive member: `TAWOS.sql`, 4,313,856,480 bytes
- License declared by publisher: Apache-2.0
- ModernBERT tokenizer revision: `8949b909ec900327062f0ebf497f51aef5e6f0c8`

## Conservative source-label mapping

The mapping is frozen before the scored analysis:

- `bug_fix`: Bug, Build Failure, Problem Ticket, Incident, Public Security Vulnerability
- `feature_enhancement`: Suggestion, Improvement, New Feature, Enhancement Request, Wish
- `documentation`: Documentation
- `research_evaluation`: Investigation
- `testing_validation`: Test Task, Test
- unsupported/ambiguous: Story, Task, Sub-task, Epic, Support Request, Question, Technical task, Technical Debt, Milestone, Release, and any unexpected type

No TAWOS native type is mapped to `maintenance`, `planning_design`, or `merge_closeout`. Resolution is retained as an outcome feature candidate, not used to overwrite work purpose; doing so would leak post-issue lifecycle information into an intake classifier.

## Sampling and measurements

1. Verify archive MD5, member size, imported table counts, foreign-key check, and issue count against the published 458,232 total.
2. Measure complete distributions for issue type, resolution, project, year, component cardinality, and character-length buckets.
3. Create a deterministic review sample using SHA-256 ordering within every observed `(project, type)` stratum, capped at two issues per stratum. Raw public issue text is stored only in the local cache; committed artifacts retain hashes, lengths, metadata classes, and aggregate counts.
4. Add the 100 longest issues as a stress sample and tokenize both samples with the pinned ModernBERT tokenizer without truncation.
5. Report median, p90, p95, p99, maximum, and the number exceeding 8,192 tokens.
6. Quantify conservative mapping coverage overall and by project. Freeze the local review manifest for later independent adjudication; do not score label precision without that review.

## Gates

- Structural pass: 458,232 nonempty issues, 39 projects, valid dates/project keys, and clean relational integrity.
- Token pass: fewer than 1% of the deterministic cross-project sample exceed 8,192 tokens. Longest-issue stress results are reported separately and do not change this threshold.
- Coverage pass for a transfer experiment: conservative mapping covers at least 70% overall and every mapped class has at least 500 examples. Failure of the per-class floor blocks eight-class transfer even if aggregate coverage passes.
- Component rule: TAWOS components remain auxiliary/project-local data regardless of their coverage.
- Label-quality gate: training remains blocked until the frozen review sample receives independent adjudication. This round may recommend that review; it cannot substitute source-label frequency for precision.

