# PR1062 assertion trim

Reviewed base:2bf73fc127dab375373ab32f0ef8cf051f9df1ef. Only gh778 assertions change.

Retain rename/path/installer/handoff repairs, obsolete-folder absence, existing assertions and disk-derived count. gh589 distribution and gh798 repairs unchanged. Remove nine added checks: new skill file/installer presence, frontmatter name, absence of old --pr wording, five Phase3b wording checks, and new index link. Remove their unused variables.

Manual source inspection: review-pr-xyz SKILL.md/install.sh exist; installer is executable; frontmatter names review-pr-xyz; ARCHITECTURE links it. Phase1 describes claims before code and early exit; operating rules3 and Phase4 describe report-only behavior. This verifies written instructions, not agent compliance. No new persistent check is warranted.

Commands: bash test/gh778-review-code-skill.sh ->25pass0fail. Red control: mkdir skills/2-daily/review-code; rerun suite ->nonzero, old-folder assertion fails; rmdir that empty fixture folder. No production skill/runtime changed.
