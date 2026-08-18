#!/usr/bin/env bash
# Classify a CI invocation as docs-only, fast, or full. Pull-request paths are read from stdin.
set -euo pipefail

event_name="${1:-}"

case "$event_name" in
  workflow_dispatch|schedule)
    # Deliberate, operator-initiated, and rare. These are the only unconditional full routes left:
    # a manual dispatch is someone asking for the whole gate, and answering it with a routed subset
    # would be answering a different question than the one asked.
    printf '%s\n' \
      'docs_only=false' \
      'pdda_needed=true' \
      'full_required=true' \
      'changed_tests=' \
      'route=full'
    exit 0
    ;;
  # GH-509 Phase 3 — `push` used to sit in the branch above, and that was 72% of the bill.
  #
  # Measured over 60 runs in ~24h: 37 pushes to `development`, EVERY ONE a full route, ~396 of ~551
  # billed minutes. Phase 1 routed pull requests and cut their average from ~16 min to 6.1 — it
  # worked, and it worked on the other 28%. The audit that opened this issue had already found the
  # same split (61/100 runs were pushes) and then exempted it.
  #
  # Pushes now classify from their pushed range exactly as a PR classifies from its diff. The caller
  # supplies the paths on stdin; a caller that cannot compute a range supplies NOTHING, and the
  # zero-path branch at the bottom of this file fails closed to full. That is deliberate reuse: the
  # fail-closed path is already tested, so a force-push or a new branch does not need its own.
  push|pull_request) ;;
  *)
    printf 'ci-route: unsupported event: %s\n' "${event_name:-<empty>}" >&2
    exit 2
    ;;
esac

docs_only=true
pdda_needed=false
full_required=false
changed_tests=""
path_count=0

add_changed_test() {
  local candidate="$1"
  [[ -f "test/$candidate" ]] || return 0
  case ",$changed_tests," in
    *",$candidate,"*) return 0 ;;
  esac
  changed_tests="${changed_tests:+$changed_tests,}$candidate"
}

while IFS= read -r path || [[ -n "$path" ]]; do
  [[ -n "$path" ]] || continue
  path_count=$((path_count + 1))

  case "$path" in
    *.md|README.txt|CHANGELOG.txt|PROJECT/*|docs/*)
      pdda_needed=true
      ;;
    *)
      docs_only=false
      ;;
  esac

  case "$path" in
    .pdda-*|utils/pdda/*|utils/pdda-local-checks.sh|test/pdda-*.sh)
      pdda_needed=true
      full_required=true
      ;;
  esac

  # These surfaces own the coordination kernel, containment boundary, frozen twins,
  # worktree safety, or CI gate itself. They require the full suite before merge.
  case "$path" in
    .github/workflows/*|validate.sh|utils/ci-route.sh|test/ci-route.sh|test/ci-workflow.sh)
      full_required=true
      ;;
    bin/tick|bin/validate-relay-block|src/*)
      full_required=true
      ;;
    relay-automation/*|utils/py/*|skills/relay-automation/*|skills/relay-xyz/*)
      full_required=true
      ;;
    skills/agent2agent/scripts/*|skills/agent2agent/install.sh|skills/agent2agent/agents/*)
      full_required=true
      ;;
    test/*worktree*|test/*containment*|test/tick-*|test/relay-*|test/agent2agent.sh|test/marathon*.sh)
      full_required=true
      ;;
    test/gh308-*|test/mktemp-trap-guard.sh|test/path-integrity.sh)
      full_required=true
      ;;
  esac

  case "$path" in
    test/*.sh)
      if [[ -f "$path" ]]; then
        add_changed_test "${path#test/}"
      else
        # A deleted/renamed regression cannot be exercised as a changed-area test.
        # Fail closed so test removal is reviewed against the complete inventory.
        full_required=true
      fi
      ;;
    *.sh|*.js|*.py)
      stem="${path##*/}"
      stem="${stem%.*}"
      add_changed_test "$stem.sh"
      normalized_stem="$(printf '%s' "$stem" | tr '_' '-')"
      add_changed_test "$normalized_stem.sh"
      ;;
  esac
done

# An empty or unreadable PR diff is not proof that the change is documentation-only.
if [[ "$path_count" -eq 0 ]]; then
  docs_only=false
  pdda_needed=true
  full_required=true
fi

if [[ "$full_required" == true ]]; then
  pdda_needed=true
  route=full
elif [[ "$docs_only" == true ]]; then
  route=docs
else
  route=fast
fi

printf '%s\n' \
  "docs_only=$docs_only" \
  "pdda_needed=$pdda_needed" \
  "full_required=$full_required" \
  "changed_tests=$changed_tests" \
  "route=$route"
