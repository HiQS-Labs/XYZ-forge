# Plan QA Relay — GH-1558 (KS-14: build_queue.py --daily-goals <issue>)

- **Issue:** #1558 (parent arc #1541, milestone KS-14)
- **Task Doc:** `PROJECT/2-WORKING/GH-1558-ks14-daily-goals.md`
- **Roadmap ID:** `rmi-01M7W542W35G5JCV8M0WX2YA9A`
- **Route:** `docs`

## Turn 1 — Producer (Antigravity)

Submitted grounded plan in `PROJECT/2-WORKING/GH-1558-ks14-daily-goals.md` implementing `build_queue.py --daily-goals <issue>` (ignoring `--since-days` for referenced issues, lifting `Daily goals*` out-of-scope for that one input, skipping checked-off `- [x]` items and code-block refs, preserving KS-02/U15 holds and default mode), with paired red/green fixture controls and no new test suite (GH-831).

Please review for Plan QA.

**NEXT: Reviewer (Codex)**

## Turn 2 — Reviewer (Codex)

STATUS: Changes requested

**Verdict: Block pending two bounded plan clarifications.** The existing classifier is the right owner and the no-new-suite approach is appropriate. This is plan QA only; implementation and runtime correctness are not approved.

1. **[Major] Preserve hold evidence before applying queue scope.** Plan lines 39–40 fetch only selected issues and scope PRs to direct or related references, but do not specify the safety context retained for those PRs. `build_queue.py:198–217` discovers operator/U15 holds only from supplied issues; `classify_prs()` uses that parked set to prevent a merge closing a held issue. Example: selected issue #10 admits PR #20 whose body closes #10 and unselected old issue #30; #30 has an operator hold or `status:held`. Fetching only selected missing issues, or filtering issues before building the parked set, loses #30's hold and can queue #20. Specify that scope limits emitted work, not safety evidence: resolve closing targets of admitted PRs (including older/unselected targets), retain their comments/labels/body for hold classification, and park on unresolved safety metadata. Add a retained manual control for this case and a KS-02 latest-owner hold/proceed control. Keep this change scoped to daily-goals mode.

2. **[Major] Define complete reference resolution and offline failure behavior.** Plan lines 35–40 accept issue/PR numbers but prescribe only `gh issue view` for missing numbers, while open PR data is separately bounded by the current PR lists. Specify issue-versus-PR resolution, what happens when an explicitly selected open PR is absent from either PR input, and fail closed for missing replay inputs instead of silently dropping a selection or calling the network. Define the empty-selection check after resolving state (all references closed must fail), and make same-repo qualification atomic so `other/repo#123` cannot fall back to a bare local `#123`. Extend the existing proposed manual controls with an explicit PR selection, a missing offline reference, all-closed references, and a foreign-repo reference. No new suite is needed.

Additional implementation reminder: `build_queue.py:377–379` independently reapplies the age cutoff when rendering folded issue annotations. Include that site in the old-issue bypass so a selected old issue folded into an admitted PR remains visible in its queue line.

Evidence: read the complete seeded plan and `skills/1-hourly/kickstart/scripts/build_queue.py`; targeted source inspection used `nl -ba skills/1-hourly/kickstart/scripts/build_queue.py | sed -n '185,235p;370,405p'` (exit 0), confirming `parked_issues(issues, ...)` feeds PR classification and `open_issues` reapplies `createdAt >= cutoff`. These are source-grounded plan gaps, not measured candidate failures. Graph tools were unavailable. No executable fixtures, tests, gates, or git commands ran; no future gate is assumed. The relay contained no embedded TAKE YOUR TURN block, so the operator's explicit reviewer protocol governed this turn.

**NEXT: Producer (Antigravity)** — amend the canonical plan to resolve these points, then return for Plan QA.

## Turn 3 — Producer (Antigravity)

Folded both Plan QA R1 blockers and the `build_queue.py:377-379` reminder into `PROJECT/2-WORKING/GH-1558-ks14-daily-goals.md`:
1. **[Major 1 — preserve hold evidence before scoping]:** specified resolving all closing targets (including unselected/older targets) of candidate admitted PRs before calling `parked_issues(...)`, retaining full comments/labels/body for hold classification, and parking any closing target whose safety metadata cannot be resolved; added Control 4(a) (admitted PR closing an unselected older held issue) and Control 4(b) (KS-02 latest-owner hold/proceed).
2. **[Major 2 — complete issue-vs-PR resolution, offline fail-closed, post-resolution empty check, atomic repo-ref parsing]:** specified offline-replay detection (zero network calls; fail-closed on missing refs or incomplete PR inputs), post-resolution empty-selection check (all-closed fails closed), atomic `(?:([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+))?#(\d+)` parsing so `other/repo#123` never falls back to bare `#123`, and `build_queue.py:377-379` `open_issues` old-issue bypass so folded selected old issues stay visible in `(closes #...)`; added Controls 3(b)/(c)/(d) and 4(c)/(d)/(e).

Please review Round 2 for Plan QA approval.

**NEXT: Reviewer (Codex)**
