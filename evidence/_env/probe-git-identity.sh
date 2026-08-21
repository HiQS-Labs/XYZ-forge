#!/usr/bin/env bash
# Probe: does a fresh temp repo (the shape the suite builds) allow `git commit`?
# Several suites create a scratch repo with `git init` and commit into it. With no
# GLOBAL user.identity, that commit fails with exit 128 and the suite reports a
# confusing downstream symptom instead of the real cause.
set -u

echo "global user.email : $(git config --global user.email 2>/dev/null || echo '<UNSET>')"
echo "global user.name  : $(git config --global user.name  2>/dev/null || echo '<UNSET>')"
echo

d="$(mktemp -d)" || { echo "mktemp failed"; exit 1; }
trap 'rm -rf "$d"' EXIT
cd "$d" || exit 1

git init -q .
echo hello > f.txt
git add f.txt

# Deliberately do NOT set a repo-local identity — reproduce what the suite's
# scratch repos experience.
out="$(git commit -q -m 'probe commit' 2>&1)"
rc=$?
echo "git commit exit: $rc"
if [ "$rc" -ne 0 ]; then
  echo "--- git said:"
  printf '%s\n' "$out" | sed 's/^/    /'
  echo
  echo "RESULT: a fresh repo CANNOT commit — undocumented prerequisite reproduces"
else
  echo "RESULT: commit succeeded — a global identity is set, finding does not reproduce"
fi
