# Work-intent labels for GitHub activity titles
Classify the primary work purpose described by an issue/PR title, not its actual completion status, priority or next action. Titles are evidence of described intent only. Exactly one label:
- defect: explicitly broken behavior, crash, incorrect result, regression, vulnerability, or a fix for such behavior. Concrete bug correction takes priority over generic feature wording.
- capability: adding a new feature, integration, supported workflow or user-facing capability, including a feat-prefixed title without an explicit existing defect.
- investigation: audit, benchmark, research, comparison, diagnosis or measurement with the primary goal of learning/assessing. A requested correction of an identified defect is defect instead.
- maintenance: dependency updates, releases, publishing, routine reconciliation, cleanup, migration/relocation, refactor preserving behavior, docs-only upkeep and administrative synchronization. If an explicit defect/new capability is primary, use that instead.
- planning: requirements, roadmap, design/spec/proposal, work breakdown or scheduling future implementation; use only when preparation/planning is the primary deliverable. A benchmark plan is investigation if its primary deliverable is evaluating a question.
- unclear: too little information, multiple equally primary intents, or no defensible assignment. Do not invent context from a repository name. If the ambiguity cannot be resolved with these rules, choose unclear and state why.
No model predictions or other split labels may be consulted to label the holdout. Give a short rationale and confidence high/medium/low. Labels must not infer that a proposed change has actually shipped.
