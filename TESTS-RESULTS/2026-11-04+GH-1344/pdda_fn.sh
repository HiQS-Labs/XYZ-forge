#!/usr/bin/env bash
# usage: pdda_fn.sh <tree> <fixture_root> <issue>
tree=$1 root=$2 n=$3
fns=$(awk '/^[A-Za-z_][A-Za-z0-9_]*\(\) *\{/{p=1} p{print} p&&/^\}/{p=0}' "$tree/utils/pdda/pdda.sh")
PDDA_REPO_ROOT="$root"; PDDA_PROJECT_DIR="$root/PROJECT"
PDDA_INBOX_DIR="$root/PROJECT/1-INBOX"; PDDA_WORKING_DIR="$root/PROJECT/2-WORKING"
PDDA_COMPLETED_DIR="$root/PROJECT/3-COMPLETED"; PDDA_MISC_DIR="$root/PROJECT/4-MISC"
eval "$fns"
if type _pdda_find_doc_for_issue >/dev/null 2>&1; then _pdda_find_doc_for_issue "$n"; echo "rc=$?"; else echo "no _pdda_find_doc_for_issue in this tree"; fi
