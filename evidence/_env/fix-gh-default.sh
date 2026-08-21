#!/usr/bin/env bash
cd "$HOME/XYZ-forge" || exit 1
. evidence/_env/prelude.sh
set -x
gh repo set-default HiQS-Suite/XYZ-forge
rc_set=$?
gh repo set-default --view
rc_view=$?
gh issue view 544 --json number,state,title
rc_issue=$?
set +x
echo "SET_RC=$rc_set VIEW_RC=$rc_view ISSUE_RC=$rc_issue"
