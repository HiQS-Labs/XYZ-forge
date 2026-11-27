#!/usr/bin/env bash
# GH-1656 final QA r1 clone probe: replay the local-merge rung's publication shape against Forge's REAL
# githooks/install.sh pre-push stub (attempt admission + gate). Shape "detached" is the r1 code
# (push HEAD from a detached candidate); shape "branch" is the fix (local <branch> at the candidate,
# push refs/heads/<branch>). Usage: real-hook-probe.sh <forge clone at the candidate> <detached|branch>
set -eu
src=$1 shape=$2
unset XYZ_SKIP_PREPUSH XYZ_ATTEMPT_CONTEXT MERGE_CLEANUP_RECORD GITHUB_ACTIONS
probe=$(mktemp -d "${TMPDIR:-/tmp}/gh1656-real-hook.XXXXXX")
test -d "$probe"
base=$(git -C "$src" rev-parse --verify HEAD)
git clone -q --bare --no-local "$src" "$probe/origin.git"
git -C "$probe/origin.git" update-ref refs/heads/development "$base"
git clone -q --branch development "$probe/origin.git" "$probe/landing"
cd "$probe/landing"
git config user.name "GH-1656 probe"
git config user.email gh1656-probe@example.invalid
bash githooks/install.sh >/dev/null
bash githooks/install.sh --check
git checkout -q --detach "$base"
git commit -q --allow-empty -m "GH-1656 probe pin"
pin=$(git rev-parse HEAD)
git checkout -q --detach "$base"
git merge -q --no-ff --no-edit "$pin"
candidate=$(git rev-parse HEAD)
if [ "$shape" = branch ]; then
  git checkout -q -B development "$candidate"
  src_ref=refs/heads/development
else
  src_ref=HEAD
fi
rc=0
git push --force-with-lease="refs/heads/development:$base" origin "$src_ref:refs/heads/development" >"$probe/push.log" 2>&1 || rc=$?
grep -E "attempt|admission|reservation|gate|pre-push|validate|PASS|FAIL|route" "$probe/push.log" | tail -15 || true
remote=$(git --git-dir="$probe/origin.git" rev-parse refs/heads/development)
printf 'shape=%s push_rc=%s base=%s candidate=%s origin=%s published=%s\n' \
  "$shape" "$rc" "$base" "$candidate" "$remote" "$([ "$remote" = "$candidate" ] && echo yes || echo no)"
