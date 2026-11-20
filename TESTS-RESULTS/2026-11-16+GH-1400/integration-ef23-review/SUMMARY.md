# Integrated candidate focused verification

Candidate: `ef23e77b24e51add4be9476191257bcbc7d7c432`.

- `followup.py`: exit 0, complete, 23/23 controls passed; includes baseline-red and discriminating refusal controls. This runs the real Jog CLI with synthetic preflight/workers and local fixture remotes.
- `test/gh280-jog-marathon-adapter.sh`: exit 0, 227 pass, 0 fail; existing integration suite with deterministic provider/GitHub shims.
- HEAD, origin, core.bare, local identity, status and worktree identity unchanged after each run. See identity JSON files and provenance.jsonl.
- `git diff --check f346d8908 HEAD`: exit 0.

No live provider tests, full gate, publication, merge, cleanup or source edits were performed. No production/unattended or whole-issue delivery claim follows. Claude independent review did not run due to the mandatory T3 cross-provider delegation route lacking a shipped relay adapter/attestation hook; see `relay-system/2026-11-16/gh1400-integrated-ef23-review-status.md`.

The task clone remains on the reviewed candidate. The reused disposable verify clone remains detached at the same candidate with its original branch retained. All evidence here is new; previous attempts remain untouched. Parent owns committing this evidence, obtaining supported independent approval and running the final qualifying gate.
