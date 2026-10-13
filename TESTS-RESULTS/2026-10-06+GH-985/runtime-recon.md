# Current official Claude runtime observations

Local CLI 2.1.289; Fable alias resolves to claude-fable-5-1 at --effort low.

Official https://code.claude.com/docs/en/hooks#stop retrieved 2026-10-06: Stop runs after main agent finishes responding, not user interrupt. StopFailure handles API errors and ignores decision output; restoring credentials requires retry in a new/steered session action, not an API-error Stop-hook guarantee. stop_hook_active is true during hook continuation. Eight-consecutive-continuation cap is documented; tool calls reset it. Existing cap comment is supported, though current wording can explain reset semantics without changing configuration. Existing block reason can be corrected without predicate changes. Native /goal is a session-scoped prompt-based Stop shortcut; optional explicit operator use only, no automatic configuration/activation.

Official https://code.claude.com/docs/en/plugins/mods/reference: turn.complete fires after ended turn; returned text shows below answer, not Stop enforcement. Existing settings Stop hook already supports the current continuation path; a mod/automatic prompt is unnecessary. PR966/issue967 own status features and unresolved keep gate.
