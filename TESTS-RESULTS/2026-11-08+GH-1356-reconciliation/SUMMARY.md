# GH-1356 closed-issue view reconciliation

The parent independently accepted and closed #1287 and #1288 before this checkpoint. Live GitHub reads confirmed CLOSED / COMPLETED for both. The existing `wave_reconcile.validate_and_update_doc` mover filed only these two unique active documents into `PROJECT/3-COMPLETED`; RELEASES `roadmap repoint --issue-num N --doc-path ...` and `roadmap move --issue-num N --section Completed` repaired their existing rows. No raw SQL, new rows, issue closures, sandbox repair, or change to acceptance criteria.

`releases_app.py check`: clean, zero failures; ten existing migration/target-date warnings. The broader issue-doc sweep was preview-only and exposed unrelated drift; it was not applied. Missing Lessons Learned warnings were advisory and did not prevent filing.

#1288 remains accepted through the documented-limit alternative: stateful campaigns remain excluded. #1356 remains incomplete; #1296 historical replay and later batch items remain outstanding. No #1358 rehearsal.
