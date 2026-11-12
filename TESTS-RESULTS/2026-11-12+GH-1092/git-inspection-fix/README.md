# Supplemental Git-inspection correction

Kimi advisory S1 and CodeRabbit4556715114 agree on an observed contradiction at old head551531fa. Original shared prompt required before/after identity inspection but prohibited all Git. Candidate implementation1d749cf7 explicitly allows read-only local Git commands while retaining mutation prohibitions and unchanged containment code. Old-source control contains the blanket prohibition; rendered candidate-prompt.txt contains explicit permission and rejects that old sentence.

Focused existing gh681 reviewer-probe suite exits0 with all cases passed in the disposable full gate clone. identity-before/after are equal, including core.bare and complete git remote -v. Historical earlier snapshots omit those fields; that limitation is disclosed in SUMMARY and no retrospective identity claim is made. This manual source/render control is not a live independent approval; the fresh reviewer must exercise read-only identity inspection and confirm normal containment.

Source/package changed after prior approval/fullgate; fresh review and classified gate remain pending. Kimi review was configured-high advisory only, not a supervisor-attested run. No merge/deployment or installed harness update.
