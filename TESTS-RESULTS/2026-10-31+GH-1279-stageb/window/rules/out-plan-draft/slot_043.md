# Plan draft: #522 feat: continuous issue admission into Jog/Marathon proposals — require remediation plan in GitHub, reviewed PRS, and readiness contracts

> draft; preflight and independent plan QA outstanding

- Request: `gh-522-18e4889aba62` (tick `slot_043`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 55/30/50/55
- Capture doc: PROJECT/1-INBOX/GH-522-ISSUE-ADMISSION.md (sha256 8ee1fcd98e949ebfb440a21b610e61c6418a3e492d86d8595f012d2639b73f7c)
- Issue sha256: 18e4889aba62c7d94942d4692e02ceea9f37d3158dbddfdbc7b827a223dd176f (updated 2026-10-30T16:54:38Z)
- Dependencies: none

## Scope

_Source: issue#522:L1 (Feasibility and intended outcome)_

**Feasible as a continuously available intake/admission service over the existing machinery.** The LLM should wake for changed eligible material and propose logical grouping; deterministic contracts decide whether membership can change. A resident LLM thinking continuously is unnecessary. The difficult work is eligibility, freshness, and coordination, not polling GitHub.

**Hard requirement from the operator:** `bug report → GitHub issue → remediation plan included in that GitHub issue → eligibility checks → Jog/Marathon candidate`. **A GitHub issue that is only a bug report does not qualify**, even with high PRS ratings, a ready label, or a locally drafted checklist. The monitor may report `NEEDS-PLAN`; it must not draft the missing plan and approve its own admission.

This is an initial design sketch, not an approved implementation plan, active marathon, or authorization to dispatch/merge.

## Acceptance criteria

_Source: PROJECT/1-INBOX/GH-522-ISSUE-ADMISSION.md:L87 (Acceptance ideas)_

- [ ] Bug-only issue with maximum PRS is held NEEDS-PLAN, including a local-only-plan case.
- [ ] Plan edits invalidate prior review/admission; unknown or revoked evidence holds.
- [ ] Missing/cyclic dependencies and declared/expanded write-set collisions hold.
- [ ] Duplicate scans, crashes and concurrent scanners yield one membership; terminal holds persist.
- [ ] Proposal/admission-only modes call neither builders nor merge commands.
- [ ] Nonempty positive fixtures and witnessed red controls have committed evidence plus
  provenance.jsonl; mutation-heavy gates run only in separate disposable full clones.

## Open questions

_missing_

## Write set

- `PROJECT/1-INBOX/recon-issue-admission.md` (PROJECT/1-INBOX/GH-522-ISSUE-ADMISSION.md:L20)
- `MACHINE-CONTRACTS.md` (PROJECT/1-INBOX/GH-522-ISSUE-ADMISSION.md:L35)

## Unresolved file names

- none

## Contract probes

- none
