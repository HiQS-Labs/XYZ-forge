# Start-task issue-exempt sibling scan clarification

The GH-970 naming rule permits `<repo-name>-<very-short-desc>-<yyyy-mm-dd>` for issue-exempt tasks, while its explicit pre-creation sibling scan only names `<repo-name>-gh<issue>-*` (`skills/1-hourly/start-task/SKILL.md:91`, `:102`). An existing issue-exempt clone can therefore be missed by that literal scan. No such duplicate was observed in the GH-1003 merge run.

Source: [older minor review on PR #971](https://github.com/HiQS-Labs/XYZ-forge/pull/971#discussion_r4186490677); tracked as a nonblocking finding in [merge batch #1003](https://github.com/HiQS-Labs/XYZ-forge/issues/1003). This is a follow-up to the already independently reviewed naming feature, outside the merge/ledger repair. No naming rule or runtime was changed here.

Next check: verify the resume instructions against one issue-exempt task clone plus its `-gate` / `-verify` helpers, then clarify the sibling pattern through the ordinary issue-first route if still needed. This note is intake, not a new admitted task.
