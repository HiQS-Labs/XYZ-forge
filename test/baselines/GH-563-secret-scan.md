# GH-563 secret-scan evidence

- Tool: TruffleHog 3.97.0
- Public repository: `HiQS-Suite/XYZ-forge`
- Scanned commit: `e80e1fcc859d5943d56978bcaace8c9e97044324`
- Scope: Git scan of the fresh public clone and its reachable refs, with updater disabled
- Result: 0 findings; 0 verified; 0 unverified
- Recorded: 2026-08-17 PDT

The raw JSON stream was retained only in a temporary audit directory and was not committed or pasted
into GitHub. A final scan is required after the audit/CI repair commit; its exact commit and sanitized
counts belong on issue #563 so the evidence can name the final immutable SHA without creating a
self-referential evidence commit.

The separate private-source history scan used the same TruffleHog version and found four unverified
`ZendeskApi` matches, all confined to two adjacent lines of one internal consult transcript duplicated
across two commits. No verified match was reported, and none of those commits or files exists in the
fresh public history. Those four matches remain a private-source owner-disposition item; no raw value
is reproduced here and the clean public-artifact result does not assert that an unverified private
match was proven harmless.
