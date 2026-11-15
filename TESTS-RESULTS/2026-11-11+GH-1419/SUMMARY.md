# GH1419 routing verification

Plan QA Approved round 2. Source d7939db9.

- Existing GH346 gateway suite: 62/62 after correcting macOS Bash empty-array handling; original 50 pass/12 fail retained. Two failures were obsolete grep controls against removed comments, replaced by actual route rejection.
- Existing manifest suite: 14/14; unsupported-Claude fixture now uses a genuinely unsupported actor.
- Existing GH280 Jog adapter suite: 227/227.
- Manual controls: nine routes retained; distinct pairs, unknown/phantom/malformed/missing-binary/same-actor refusal; real dispatcher child identity and peer; real Claude/Codex Python shim identity reached before model execution; actual recovery-function controlled timeout/handoff stops after one retry. Controlled recovery is not a live provider timeout.
- Baseline Claude admission refusal and scalar overwrite reproduced from committed pre-change source.
- Disposable clone identity remained clean/non-bare/canonical origin/no local identity. No full qualification yet.
- An initial manual invocation used task CWD; it exercised temporary-directory dispatch and mocked post-identity RTL boundary, no test suite or provider call. Repeated in disposable clone for retained result. Evidence-copy command initially used gate CWD and failed before writes; corrected to task CWD.

Existing Marathon chain suite 35/35 passed in disposable clone. Actual manifest CLI accepted all nine supported reviewers and rejected phantom/unknown routes without provider binary requirements.

Live Claude route reached the real isolated reviewer, which appended a source review. Provider exited 1 (error_max_budget_usd, $0.5283504 reported against existing $0.50 cap); containment also rejected author evidence/JSDoc edits made concurrently in task CWD. Harness exit 6, terminal approval correctly revoked. Own files restored byte-for-byte from its orphan backups; no peer files involved. This is route-execution evidence, NOT successful independent approval or an end-to-end relay success. No live retry or budget increase. Independent final Codex QA Approved round 1 at reviewed ac56484c; normal full push qualification subsequently passed. Final GH346 actual-CLI assertion rerun passed 62/62. No overnight progression, provider quality grade, merge or deployment claim.

Full push attempt 1 refused at 611c012b after 538.228s: marathon-root-audit and checkjs failed. Corrected missing exported-function JSDoc and explicit MARATHON_ROOT on two recognition-only commands; production runtime unchanged. Focused repairs: checkjs 6/6, root audit 169 invocations, GH346 62/62. No gate bypass. Attempt 2 normal full push PASS on a9090e72d058ea73af478e726c41108be86b3d58: hook 526s, elapsed 529.515s, cap1800. Postgate clone clean/non-bare/canonical origin/no local identity.

Hosted review identified SmallCode shim disabling isolation. Shared execution probe now refuses SmallCode reviewers when isolation is enabled/default, retaining builder and explicitly non-isolated admission. Manual baseline admission witnessed, fixed refusal and preservation controls pass; GH346 62/62. Fresh final QA and normal qualification required for this correction.

## Hosted-review isolation correction qualification

Independent final QA round 2 approved f39a5e42. Normal full push gate on 2bb4f727 passed 408/408 in 551s (553.149s elapsed). Disposable clone remained clean, non-bare, canonical origin, without local identity override. SmallCode reviewer with isolation enabled refuses before dispatch; explicit nonisolated reviewer and builder behavior remain supported. Original failures and qualifications retained. Hosted checks on final evidence head remain required.
