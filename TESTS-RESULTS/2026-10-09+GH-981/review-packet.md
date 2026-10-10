# PR982 current-development integration QA

Goal: independently review the optional Paperclip dashboard for landing into development, as requested by the operator's current merge-cleanup of all open XYZ PRs except #930. This request establishes intent to retain/land the add-on, subject to actual merge readiness. Do not merge, push, change product code, run a server/browser, or run test suites in a relay worktree.

Operational envelope: a local optional developer dashboard, launched explicitly, loopback only. Surgical, DRY, reasonable safety/security/stability. No new test suites, guards, gate machinery or speculative enterprise requirements. Follow AGENTS.md and the relay reviewer measured-read-only boundaries. No validate.sh, test/*.sh, pytest or executable fixtures in your worktree.

Pinned candidate: c4ef7f3dbd2ed937150fd84d3aef0f0d2335946e. It integrates PR head 7ea3c7d3c76a7225b790e2fafd635eb1ded8d1d2 and development 47fb72dfcb (verify the complete SHA locally). The conflict set was only releases.db and releases.sql. The supported resolver kept development's generation and replayed only GH981 through the writer. All eight add-on files match the original PR bytes. No runtime edits by the merge-cleanup producer.

Read all addon files under addons/paperclip-dashboard, its canonical plan PROJECT/2-WORKING/GH-981-PAPERCLIP-DASHBOARD.md, prior final QA relay-system/2026-10-06/gh981-final.codex.md and TESTS-RESULTS/2026-10-06+GH-981/SUMMARY.md. Trace existing Flightdeck readers/selectors one level out where relevant. Compare both PR-head and integration-base ancestry rather than relying on stale success claims.

Questions:
1. Does the add-on remain optional and inert until explicitly launched? Do finite asset routes, loopback binding, request/Host limits, CSP, text rendering and demo/live separation satisfy the stated local envelope?
2. Are calls to existing Flightdeck projections, selectors and readers compatible with today's integrated signatures and state shapes? Provide concrete input/path evidence for an incompatibility.
3. Does ledger-only integration preserve GH981 and current development without changing dashboard runtime bytes? Are non-ledger differences only the intended addon/docs/evidence compared with development?
4. Do original browser/manual red controls support their bounded claims? Treat the old five Darwin os.waitid failures and interrupted Lanes timer observation as openly unverified, not green or a new feature failure without evidence. The producer will run the required full gate in a disposable full clone after this implementation review; it has not run yet on c4ef7f3d.
5. Is any code blocker newly exposed by integration? Report file:line and concrete failure/input. Review maintainability and unnecessary machinery proportionately. Do not ask for new tests where GH831 forbids them.

Output a substantive Reviewer block with whole-file-sweep yes/no, file:line evidence and implementation verdict. A behavior-change finding must carry Observed input:, Affected scope:, Falsifier:. VERDICT: PASS and STATUS Approved only if implementation review is clean; explicitly state the full merge-time gate remains outstanding and approval is not gate qualification. On findings use VERDICT: FAIL, STATUS Open and hand back to codex-producer. No edits outside the relay file.
