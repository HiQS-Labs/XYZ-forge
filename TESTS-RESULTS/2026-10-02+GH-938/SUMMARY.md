# GH-938 verification — relay-xyz First-time setup (docs only)

Tested head: `204750c576f2bdc12764d42915bbcdedf2985388` (branch `fix/gh938-relay-xyz-managed-setup`),
base `5212dae44bf5e1873be4689d63ef792ec1b6d93e` (origin/development). Environment: Linux box
(Debian, node v20.19.2), disposable full clones. Provenance: `provenance.jsonl` (sha256 per artifact).

| Check | Result |
|---|---|
| `test/find-harness.sh` (pins :41, :43) | 50 pass, 0 fail |
| `test/gh678-installer-live-links.sh` | pass (24 installers) |
| `test/path-integrity.sh` | 3 pass, 0 fail |
| `test/gh681-reviewer-probe-rules.sh` | all cases passed |
| `test/gh346-gateway-allowlists.sh` | 55 pass, 0 fail |
| `test/gh278-turn-timeout-parity.sh` | 11 pass, 0 fail |
| Red control: bogus repo path token in SKILL.md | path-integrity exit 1 (expected), restored exit 0 |
| Red control: exact CWD-relative `--check` line | find-harness :43 pin FAIL (expected), restored 50/0 |
| Wording grep `Deployed Skills` | head: line 73; base: no match |
| Full `./validate.sh` (Large tier) | exit 1: 399/410 passed, 11 failed, 14m47s, 2026-10-02 19:54–20:09 PDT |
| Base attribution of the 11 failures | all 11 fail on base `5212dae4` with the same failing assertions — `failure-attribution.md` |

The 11 full-gate failures are environment/pre-existing on this Linux box, not caused by this diff
(a one-section markdown edit no failing suite reads): gh610-claude-subscription (real Claude probe),
gh399-packet-acceptance-continuation, gh390-timeout-attribution and gh492-idle-kill (network probe
classification), gh505-relay-attest (N3), gh402-board-sync, gh544-pre-push-gate (criss-cross fixture),
swarm-preflight (T37c/T38 stale-lock), gh123-lock-progress-bound (timing), gh280-jog-marathon-adapter
(H2 containment), gh436-merge-cleanup. Each also failed alone in the gate's serial re-run. Hosted CI on
the PR is the cross-platform signal.
