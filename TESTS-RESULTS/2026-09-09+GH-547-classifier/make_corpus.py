from pathlib import Path
import json
# Hand-authored public/synthetic development screen; no private activity or generated paraphrase expansion.
data={
'bug_report':(
'''Opening an issue: the dashboard crashes when the project has no commits.
The user reports that pressing refresh freezes the window.
Reproduction steps: select an empty repository, then observe the exception.
A newly filed defect describes stale results after switching branches.
The reporter attached an error trace from yesterday's failed launch.
Issue description: the counter displays negative values after a restart.
A customer says the application loses saved preferences.
New ticket documents duplicate notifications with a minimal example.''',
'''An operator describes missing history and supplies steps that reproduce it.
Incoming defect: selecting a deleted folder terminates the application.
The newly opened ticket says startup fails; no patch is attached.
A maintainer records an unexpected timeout as a reproducible problem.'''),
'implementation':(
'''The patch adds a null check before reading the project settings.
Changed the parser to accept an optional timestamp field.
The commit replaces the retry loop with a bounded attempt counter.
Added a regression test and updated the serializer implementation.
The diff removes an unused helper and updates its two callers.
Implemented a cache key that includes the repository identity.
The worker modified three source files to handle empty input.
Updated the configuration loader to reject malformed values.''',
'''This revision introduces a new parameter and adjusts the functions that call it.
The submitted diff changes an off-by-one comparison in the scheduler.
A source edit now preserves the original exception when cleanup fails.
The author added support for paths containing whitespace.'''),
'validation_failed':(
'''The test runner exited with code 1 after an assertion mismatch.
CI finished red because the integration suite timed out.
The validation command failed: expected four rows but found three.
A failing test shows that the new serializer drops the identifier.
The linter rejected the change for an undefined variable.
The build did not complete because a dependency could not be resolved.
The regression suite reported two failures and stopped.
The gate refused publication after finding a broken reference.''',
'''Verification terminated unsuccessfully: the observed response differs from the fixture.
The workflow concluded failure when compilation encountered a syntax error.
An automated check rejected the artifact because required metadata was missing.
The smoke run returned a nonzero status after the server failed to start.'''),
'validation_passed':(
'''The test runner exited with code 0 and all assertions passed.
CI finished green for the current commit.
The validation command completed successfully with zero failures.
All integration checks passed on the candidate revision.
The linter accepted every changed file without errors.
The build completed successfully and produced the expected artifact.
The regression suite reported 120 passes and no failures.
The gate verified all required references and returned success.''',
'''Verification completed successfully; actual responses match every fixture.
The workflow concluded success after compilation and its checks completed.
Automated checks accepted the artifact and found all required metadata.
The smoke run returned zero after confirming that the server responded correctly.'''),
'review_requested':(
'''Please review this pull request before we merge it.
The author requested an independent reviewer for the patch.
A maintainer asks for feedback on the proposed API change.
The branch is ready for code review; approval is still pending.
Assigned the pull request to a reviewer for inspection.
Could someone assess whether this diff preserves compatibility?
The producer handed the committed changes to the QA reviewer.
Requesting a second opinion on the final implementation.''',
'''The developer invites a teammate to inspect the changes before landing.
This proposal awaits an independent assessment of correctness.
The author asks a colleague to examine the patch and leave a verdict.
A review invitation was sent for the latest revision.'''),
'merged':(
'''GitHub reports that the pull request was merged into development.
The squash merge completed and the target branch includes the change.
The pull request state is MERGED with a recorded merge timestamp.
The maintainer landed the approved patch on the integration branch.
The feature branch was integrated into the main line successfully.
The merge operation succeeded and created a new target commit.
The change is now included in development after a completed merge.
The repository records the pull request as merged, not merely closed.''',
'''The platform confirms successful integration of the proposed commits into the target branch.
The approved revision has landed; its resulting commit is present on development.
The pull request now has a merge commit and a nonempty mergedAt field.
The source changes were incorporated through a completed squash operation.''')}
rows=[]
for label,(train,test) in data.items():
 for split,lines in [('train',train),('test',test)]:
  for i,text in enumerate(lines.splitlines()):rows.append({'id':f'{label}-{split}-{i+1}','label':label,'split':split,'text':text})
p=Path(__file__).parent
(p/'corpus.json').write_text(json.dumps(rows,indent=2)+'\n')
