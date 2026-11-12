# Supplemental Git-inspection correction

Kimi advisory S1 and CodeRabbit4556715114 agree on an observed contradiction at old head551531fa. Original shared prompt required before/after identity inspection but prohibited all Git. Candidate implementation1d749cf7 explicitly allows read-only local Git commands while retaining mutation prohibitions and unchanged containment code. Old-source control contains the blanket prohibition; rendered candidate-prompt.txt contains explicit permission and rejects that old sentence.

Focused existing gh681 reviewer-probe suite exits0 with all cases passed in the disposable full gate clone. identity-before/after are equal, including core.bare and complete git remote -v. Historical earlier snapshots omit those fields; that limitation is disclosed in SUMMARY and no retrospective identity claim is made. This manual source/render control is not a live independent approval; the fresh reviewer must exercise read-only identity inspection and confirm normal containment.

Source/package changed after prior approval/fullgate; fresh review and classified gate remain pending. Kimi review was configured-high advisory only, not a supervisor-attested run. No merge/deployment or installed harness update.

## Current remediation verification — completed

Source correction: 1d749cf738858b084816e1d11c61a6153e2ffcef; focused evidence:
32c838c80d6a7c80aa1f1d8552fa26a26e4c3050; approved review-artifact/gated commit:
bf7b0920399485b88f1b4e66c9e5afdb72ba7024. Fresh Codex remediation round 3 Approved,
supervisor exit 0 and attestation in relay-system/2026-11-12/gh1092-remediation-r3.codex.md.
Reviewer actually executed read-only Git probes; no suite run is attributed to that review.
This closes Kimi advisory S1 / CodeRabbit 4556715114 through measured correction and independent QA.

Fresh classified full/tier3 local gate on exact bf7b0920: **408/408 passed**, Python layer
**21 passed**, native validate.sh receipt exit 0, mode parallel, scope full. Complete external
before/after snapshots are identical, including configured core.bare and complete remote -v.
Command: PATH=<prepared gate venv>/bin:$PATH RELAY_SELF_SUFFICIENCY_SKIP=1 bash validate.sh.
The standard live self-sufficiency skip remains disclosed; this is not promotion qualification
or a claim that every live integration ran. Gate ran once in the existing disposable full clone.
Original session handle was unavailable at handoff; completion is established by the owned process
ending, decisive log and native final receipt. No duplicate gate was launched.

CodeRabbit 4556715121 is valid for historical snapshots: missing core.bare/remote-v fields remain
unavailable and historical receipts unchanged. New complete full-before/full-after brackets,
full-gate.log and full-gate-receipt.json are under git-inspection-fix/. Do not infer historical
remote/config stability from this new run. New implementation-sha256.json is separate from
original implementation hashes and pins the revised source/package.

Source pushed first at tested bf7b0920 via canonical receipt writer/import for the same SHA and
native full-receipt reuse (source-push.log), with no hook bypass. This evidence-only publication
uses the native docs gate. Kimi at 551531fa was ACP-configured K3.1 Pro thinking=high advisory
only: the shipped CLI cannot preserve high, so no Kimi driver exit/attestation or Kimi approval
is claimed. Broader Forge1092/LTVera981 browser replay and policy-owner decisions remain open.
No merge, deployment, installation, protected LTVera primary or PR992 change. Task/gate clones
are retained for local evidence and parent handoff; no unsafe retirement attempted.
