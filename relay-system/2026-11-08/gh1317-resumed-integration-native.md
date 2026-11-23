# GH-1317 resumed integration QA
Reviewer: native Codex agent /root/pr1318_resumed_integration_review, inherited model/settings.
Reviewed head: 78452569a870f6d0bbde04a1ac753ecba1c0f6ff
Scoped verdict: PASS; no integration blocker. No relay-driver attestation or prior-cap reset claimed.

- _probe_due remains strictly >3600 and shared by rules/Codex (harness.py:194–198,229,256).
- v2/v3 prompt hash checked before dispatch construction; mismatch unbilled/calledFalse (255–286).
- Reservation/settlement and no-call flags remain consistent (1324–1333,1619–1623).
- Cache usage parses only actual subprocess returns; warm cache requires reported call; rules report calledFalse (233,289–340,1276–1279,1622–1623).
- Cold deferral uses local decisions without model reservation; defaults disabled (1035,1125,1610–1617).

Reviewer read requested diffs, snapshot/cache/adapter/settlement/caller paths and frozen contract/prior pilot. No edits, suites, fixtures, providers, commits or pushes. Runtime qualification remains the parent's separate fresh full gate.
