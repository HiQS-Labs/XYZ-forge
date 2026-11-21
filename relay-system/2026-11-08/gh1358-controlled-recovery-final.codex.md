# Independent Codex controlled recovery QA

Reviewer: native /root/recovery_final_qa. Verdict: Conditionally Approved; no blocking source or recovery defect. Read-only review, no tests/mutations/PR polling.

Verified all recovery provenance hashes; W1 preserved exec1 verbatim and exec2 gained exactly retry1 plus projected reason. Known original-receipt trace-text limitation is disclosed. Existing lock/state/resume/checkpoint paths, exact receipt checks and peer ancestry preservation were reviewed.

Candidate8d541d012 runtime SHA256169e57aeb0e19926c55c11cc7e272778c06dad3bd0c25bf8c8784c62737992c9 matches prior approval. Since focused-tested c6cc2d6d7, only escalation/transcript records changed; reuse7/7,23/23,227/227 supported. Invocation changes only gate configuration; effective1800s gate,900/900workers,lane2. Actual satisfied-lane skip supports no builder refire.

Final conditions: retain fullgate receipt/log and Marathon result; bind gateSHA to reviewed source and publishedhead. Confirm attempt hashd2565905a3f76fb1f98294f476b29515b3a671d28e6e27ac75c4f8924cd6aff2, unchanged oldtimeout bytes, cleanpublished primary/peer ancestors, disabledschedules. Commit effectivecaps/start/result/provenance/QA. Update currentGH1254 status/budget wording to distinguish recovery from historical900/720 window. Original1358gaps stay visible; scopedclockdelivery/assistedrecovery only, no qualification/merge approval. Hostedchecks parent-owned.
