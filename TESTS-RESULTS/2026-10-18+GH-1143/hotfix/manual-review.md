# Scoped manual hotfix integration evidence

Base development: 3a6dde9e66decfff4be1ee999ac3d59c6ff059b4. Original PR1147 head:
9004226c96f1277cb584f138116811da3e548bcc. Only its docs/evidence imported; current ledger
preserved through supported CLI add/rate/accepted-start. ledger-preservation.txt compares
all baseline tables/rows: generation increment, one GH1143 row, three appended op receipts
and three appended work events. No existing rows, labels or receipts removed/changed.

Operator explicitly authorized the Express risk-based wording and direct-development hotfix,
then explicitly allowed one-off manual integration outside express.py. Normal hooks stay on;
no executable code, XYZ_SKIP_PREPUSH, no-verify, force push or automated new authority.
Driver source inspection: docs-only rejects SKILL.md; cmd_land and closeout set bypass env.
That mismatch is disclosed; editorial/skill docs use proportionate review, not filename bans.
Policy authority changes require explicit scoped approval. Inspect both normal driver and
manual paragraphs: manual procedure keeps independent review, canonical writers, exact-head
identity and ownership, normal hook, fast-forward and race/refusal checks. No automatic flag.

Existing skill quick_validate.py: PASS for defect-campaign and express (<1s each).
PDDA deterministic docs gate: PASS in 40s, zero errors/37 existing warnings. LLM doc-ready
self-skipped. RELEASES check: PASS, zero failures/10 existing migration/date warnings.
Combined staged changed-path classifier: docs_only=true, route=docs, tier=1, full_required=false.
Full changed-path whitespace check passed after normalizing trailing whitespace on four
imported transcript lines (original raw transcript remains in remote original PR branch).
No new scripts, tests, cases, assertions, fixtures, workflows or runtime changes.

Original final QA used round1/3; focused policy/integration review now uses round2/3.
Original plan rejection/override and final attestation remain intact. This is not a cap reset.
Future direct push will compare advertised development SHA to the pinned base, prove clean
identity and ancestry, use installed normal hook and a non-force HEAD:development push.
Concurrent development movement requires reconciliation and fresh review of material changes.
No actual campaign or remediation performed; #1133 stays paused and #1136 work untouched.
