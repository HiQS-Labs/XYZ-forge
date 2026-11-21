# GH1381 independent native Codex plan QA

Reviewer: native agent /root/plan_qa, separate reviewer, 2026-11-08.
Verdict: Approved; no blocking findings.

Remove both flag construction and outer preview, obsolete suppression state and stale comments. Preserve stacked retargeting, helper signature, strategy, exact-head pin and remote confirmation. Update existing failed-retarget test cleanup and names. gh v2.101.0 defaults deletion false; explicit strategy and captured output avoid interactive deletion selection. Controlled command capture proves invocation, not a real GitHub merge/deletion trace. Baseline red must use ordinary path (failed-retarget already suppresses deletion).

Source: https://github.com/cli/cli/blob/v2.101.0/pkg/cmd/pr/merge/merge.go
