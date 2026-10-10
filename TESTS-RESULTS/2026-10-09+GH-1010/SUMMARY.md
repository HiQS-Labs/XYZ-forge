# GH-1010 verification

Implementation tested: `aa479b18`; base: `ecec5561`. All executable policy/focused checks ran in
a separate disposable full clone. `identity-before.json` equals `identity-after.json` (HEAD,
origin, bare flag, local email); working tree clean after restoring the deliberate mutation.

- Existing cleanup suite: **180 tests, OK**, 257.522 seconds.
- Manual policy matrix: missing/key-absent/false/true, every explicit method, invalid JSON/types/keys,
  unreadable/dangling policy, direct writer and landing refusal, hosting disabled/unknown/refusal,
  `--merge` command and MERGED verification, no-I/O JSON reporter, early malformed-policy refusal.
- Red control: copy the source file, replace only `execute_pr_merge`'s policy check with
  `strategy = strategy or "squash"`, then assert `not execute_pr_merge(7, root, "squash", True)`
  against an opted-in temporary root. It failed exactly because forbidden squash reached the
  dry-run writer (exit 1). Restore from the copy; full policy probe returns exit 0.
- Vendoring: install with `--no-register` into a new temporary Git repository; no policy file is
  copied from Forge. Write false, repeat vendoring, compare bytes, invoke the vendored reporter:
  unchanged policy, effective squash. Installer output retained only on failure; assertions passed.
- Local Git fixture: create base + feature commit, merge --no-ff onto integration, confirm feature
  HEAD ancestry and two parents. Squash the same feature from base: identical file blob, feature
  HEAD not an ancestor. This proves the distinction, not a live GitHub landing.
- Reviewer shim: existing 43 checks pass. Plan relay Approved, exit 0. PDDA frontmatter/status:
  exit 0, zero errors. See `provenance.jsonl` for exact artifact digests and revision attribution.

No live GitHub merges, host settings mutations, new test suites, or teardown were performed.
Final independent review and gated publication are recorded in the plan and PR when complete.

Final full pre-push gate: **409 / 409 passed**, 909 seconds, on `a0547ec15ea47fddb6d34a9260dbabca92f79aad` in a separate full clone. Git identity unchanged and working tree clean. The initial pooled `gh648-l4-285-revalidate.sh` attempt raised `PermissionError` while observing/cleaning a process group; the gate's built-in isolated retry passed. Both observations retained; the underlying cause is unconfirmed. Gate and push exited 0, without bypass. Plan and final Codex relay QA are Approved with exit-0 attestations. Subsequent edits are evidence/task-status documentation only.
