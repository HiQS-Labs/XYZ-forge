# Independent Claude Code Fable 5.1 high QA

Operator-requested review of PR953 at92a8a230. Model identity confirmed in CLI modelUsage; effort high passed through the native shared flag. The first-party subscription preflight succeeded. Shipped relay completed, exit5: valid changes-requested handback, not a stall or approval.

Verdict FAIL. B1: the domain/metamorphic oracle CLIs launch session-isolated commands but lack a SIGTERM cancellation boundary; the reviewer observed a surviving command after the outer timeout wrapper and after direct SIGTERM. The reviewer cleaned both survivors. Base comparison remains unverified; do not claim a proven regression until a disposable-clone control compares it.

S1 is non-blocking: the touched metamorphic state snapshot still uses literal .git/config and misses linked-worktree common config. The path-shape observation is recorded, but the complete Git-mutation falsifier was not run.

Full signed findings, source citations, commands and limitations: relay-system/2026-10-03/gh949-fable-qa.md. Runtime code unchanged; PR returned to draft pending blocker disposition. Earlier green tests and Codex approvals remain historical evidence, not an override of this finding.
