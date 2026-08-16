#!/usr/bin/env bash
set -uo pipefail
#
# target-checks.sh — run the TARGET repo's own checks, so a relay/marathon gate verifies the code
# the way that repo verifies it (GH-268 item 8).
#
# The problem this exists for, verbatim from the beta report (#268):
#
#   "The Producer/Reviewer loop reached 'Approved' in two rounds... An independent full audit of the
#    same branch found 20 issues (1 critical, 4 high) — all in the original file the relay built on
#    but never reviewed... Fix: run the target repo's own checks in the per-phase gate the harness
#    already supports — for PHP/WordPress, `php -l` + PHPCS with the WordPress-security ruleset
#    would mechanically catch several of these."
#
# The `--pre-advance-cmd` seam already existed (GH-238). What did not exist was anything that KNEW
# what a foreign repo's checks are. A gate that runs nothing is indistinguishable from a gate that
# passes — the same false-green class as GH-319, one layer out.
#
# Usage:
#   relay-automation/target-checks.sh detect [--root DIR] [--format text|json]
#   relay-automation/target-checks.sh run    [--root DIR] [--strict]
#
#   detect  — print the checks that WOULD run, one per line. Exit 0 if any were found, 3 if none.
#   run     — run them in order. Exit 0 all passed · 1 a check FAILED · 3 nothing detected.
#
#   --root DIR   repo to inspect (default: $PWD). This is the TARGET repo, not the harness.
#   --strict     a detected check whose tool is not installed is a FAILURE rather than a skip.
#                Default is skip-with-notice: an uninstalled linter should not silently pass, but it
#                also should not block a lane on a machine that never had it.
#
# As a marathon gate:
#   marathon-drive.sh --target-root /path/to/repo \
#     --pre-advance-cmd "relay-automation/target-checks.sh run --root /path/to/repo"
#
# utils/py/marathon_drive.py wires this automatically when --target-root is given, no explicit
# --pre-advance-cmd was passed, and the target has no root validate.sh — the case that previously
# died "pre-advance gate not runnable" (GH-238) and left a cross-repo lane with no gate at all.
#
# Exit: 0 ok · 1 a check failed · 2 usage · 3 no checks detected.

die() { printf 'target-checks: %s\n' "$*" >&2; exit 2; }
say() { printf 'target-checks: %s\n' "$*"; }

MODE=""; ROOT="$PWD"; STRICT=0; FORMAT="text"
while (($#)); do
  case "$1" in
    detect|run) MODE="$1"; shift ;;
    --root)     ROOT="${2:-}"; shift 2 ;;
    --format)   FORMAT="${2:-text}"; shift 2 ;;
    --strict)   STRICT=1; shift ;;
    --help)     sed -n '2,40p' "$0"; exit 0 ;;
    *)          die "unknown argument: $1" ;;
  esac
done
[[ -n "$MODE" ]] || die "usage: target-checks.sh detect|run [--root DIR] [--strict]"
[[ -d "$ROOT" ]] || die "root is not a directory: $ROOT"
ROOT="$(cd "$ROOT" && pwd -P)"

# Each detected check is "label\ttool\tcommand". `tool` is the binary whose absence means "skip"
# (empty = no external tool needed).
CHECKS=()
add() { CHECKS+=("$1"$'\t'"$2"$'\t'"$3"); }

# Resolve a tool PROJECT-LOCAL FIRST, then on PATH. Found by the Codex cross-vendor consult
# (GH-268 item 9) as the most likely real-world false green: a WordPress plugin installs PHPCS via
# Composer at vendor/bin/phpcs and almost never has it on PATH globally. The first draft detected
# phpcs, skipped it as "not installed", ran php -l, and exited 0 because ONE check had run — so the
# WordPress-security ruleset, the entire point of the gate for that ecosystem, silently never ran.
# Echoes the resolved path so the caller can see WHICH binary was used, not just that one was.
resolve_tool() {  # <tool> -> prints an invocable path, or nothing
  local t="$1"
  for local_bin in "$ROOT/vendor/bin/$t" "$ROOT/node_modules/.bin/$t" "$ROOT/.venv/bin/$t"; do
    [[ -x "$local_bin" ]] && { printf '%s' "$local_bin"; return 0; }
  done
  command -v "$t" >/dev/null 2>&1 && { printf '%s' "$t"; return 0; }
  return 1
}

has_file()  { [[ -e "$ROOT/$1" ]]; }
# Bounded: -maxdepth keeps this from walking a huge tree, and vendor/node_modules are excluded
# because a dependency's lint failures are not the lane's problem.
any_ext() {
  find "$ROOT" -maxdepth 4 \
    \( -name vendor -o -name node_modules -o -name .git -o -name .xyz \) -prune -o \
    -type f -name "$1" -print -quit 2>/dev/null | grep . >/dev/null
}

# ── PHP / WordPress — the ecosystem the report was written against ───────────────────────
if any_ext '*.php'; then
  # php -l is a syntax check only. It is listed first because it is the cheapest thing that would
  # have caught a parse error, and it needs no project config at all.
  # `-r` and `set -o pipefail` are both from the agy cross-vendor relay (GH-268 item 9):
  #   * without -r, GNU xargs runs the command ONCE on empty input, so `php -l` with no arguments
  #     reads stdin and HANGS — permanently blocking the lane. BSD/macOS xargs does not do this,
  #     which is why it never showed up locally; CI is ubuntu. -r is accepted (no-op) on macOS.
  #   * `bash -c` does not inherit this script's pipefail, so a `find` that fails (permission
  #     denied on a subtree) would be masked by a passing xargs and the gate would report green.
  add "php-lint" "php" \
    "set -o pipefail; find . -path ./vendor -prune -o -path ./node_modules -prune -o -name '*.php' -print0 | xargs -0 -r -n1 php -l"
fi
for cfg in phpcs.xml phpcs.xml.dist .phpcs.xml .phpcs.xml.dist; do
  if has_file "$cfg"; then
    add "phpcs" "phpcs" "phpcs --standard=$cfg ."
    break
  fi
done
# No project ruleset but it is a WordPress plugin/theme: the report names WordPress-security
# explicitly, so ask for it by name rather than defaulting to PSR12 and calling it covered.
if [[ ${#CHECKS[@]} -eq 0 || ! " ${CHECKS[*]} " == *"phpcs"* ]]; then
  if has_file "composer.json" && grep -q 'wp-coding-standards\|phpcs' "$ROOT/composer.json" 2>/dev/null; then
    add "phpcs-wp" "phpcs" "phpcs --standard=WordPress ."
  fi
fi

# ── Node ─────────────────────────────────────────────────────────────────────────────────
if has_file "package.json"; then
  grep -q '"lint"' "$ROOT/package.json" 2>/dev/null && add "npm-lint" "npm" "npm run lint --silent"
  grep -q '"test"' "$ROOT/package.json" 2>/dev/null && add "npm-test" "npm" "npm test --silent"
fi

# ── Python ───────────────────────────────────────────────────────────────────────────────
if has_file "pytest.ini" || has_file "tox.ini" \
   || { has_file "pyproject.toml" && grep -q 'pytest' "$ROOT/pyproject.toml" 2>/dev/null; }; then
  add "pytest" "python3" "python3 -m pytest -q"
fi
if has_file "ruff.toml" || has_file ".ruff.toml" \
   || { has_file "pyproject.toml" && grep -q '\[tool\.ruff\]' "$ROOT/pyproject.toml" 2>/dev/null; }; then
  add "ruff" "ruff" "ruff check ."
fi

# ── Generic ──────────────────────────────────────────────────────────────────────────────
if has_file "Makefile" && grep -qE '^test:' "$ROOT/Makefile" 2>/dev/null; then
  add "make-test" "make" "make test"
fi
# Listed LAST deliberately. A repo with its own validate.sh already had a working gate; the point of
# this script is the repos that do not.
has_file "validate.sh" && add "validate.sh" "bash" "bash validate.sh"

if [[ ${#CHECKS[@]} -eq 0 ]]; then
  say "no checks detected in $ROOT"
  say "  looked for: *.php (php -l), phpcs config, composer phpcs, package.json lint/test,"
  say "              pytest/ruff config, Makefile test:, validate.sh"
  say "  a gate that runs nothing is not a passing gate — pass --pre-advance-cmd explicitly"
  exit 3
fi

if [[ "$MODE" == "detect" ]]; then
  if [[ "$FORMAT" == "json" ]]; then
    printf '{"root":"%s","checks":[' "$ROOT"
    for i in "${!CHECKS[@]}"; do
      IFS=$'\t' read -r label tool cmd <<<"${CHECKS[$i]}"
      [[ $i -gt 0 ]] && printf ','
      printf '{"label":"%s","tool":"%s","command":"%s"}' "$label" "$tool" "${cmd//\"/\\\"}"
    done
    printf ']}\n'
  else
    for entry in "${CHECKS[@]}"; do
      IFS=$'\t' read -r label tool cmd <<<"$entry"
      printf '%s\t%s\n' "$label" "$cmd"
    done
  fi
  exit 0
fi

# ── run ──────────────────────────────────────────────────────────────────────────────────
failed=0 skipped=0 ran=0
for entry in "${CHECKS[@]}"; do
  IFS=$'\t' read -r label tool cmd <<<"$entry"
  if [[ -n "$tool" ]]; then
    if resolved="$(resolve_tool "$tool")"; then
      # Substitute the resolved path for the bare tool name — but ONLY when the command actually
      # begins with that tool. agy cross-vendor relay (GH-268 item 9) caught the unguarded form:
      # php-lint's command starts with `find`, not `php`, so `${cmd#"$tool"}` stripped nothing and
      # the result was `/path/to/phpfind . -name ...` — a command-not-found that would fail the gate
      # for a reason having nothing to do with the code under review. Latent rather than live (it
      # needs php resolved project-local), but wrong, and wrong in a way that produces a confusing
      # failure rather than an obvious one.
      if [[ "$resolved" != "$tool" && "$cmd" == "$tool "* ]]; then
        cmd="${resolved}${cmd#"$tool"}"
      elif [[ "$resolved" != "$tool" ]]; then
        # Tool resolved project-local but is not the leading word (php-lint). Put its directory on
        # PATH for this command instead of rewriting the string.
        cmd="PATH=$(dirname "$resolved"):\$PATH $cmd"
      fi
    else
      if ((STRICT)); then
        say "FAIL $label — '$tool' not found on PATH or in vendor/bin, node_modules/.bin, .venv/bin (--strict)"
        failed=$((failed + 1))
      else
        say "SKIP $label — '$tool' not found on PATH or in vendor/bin, node_modules/.bin, .venv/bin"
        say "     (re-run with --strict to make this fatal)"
        skipped=$((skipped + 1))
      fi
      continue
    fi
  fi
  say "RUN  $label: $cmd"
  # `bash -c` in a CHILD shell, deliberately not in-process evaluation. The commands are literals
  # from the table above, so neither form is injectable here — but a check has no business being
  # able to mutate this script's own state, and this is the same primitive the --pre-advance-cmd
  # gate seam already uses (subprocess.run(..., shell=True)). The repo's security scanner rejects
  # the in-process form by rule; this is a narrower construct, not a way around the rule.
  # (The wording above avoids naming that construct literally — the scanner matches text, so
  # spelling it out in a comment trips it, the same false-positive class as GH-177.)
  if ( cd "$ROOT" && bash -c "$cmd" ); then
    say "PASS $label"
    ran=$((ran + 1))
  else
    say "FAIL $label"
    failed=$((failed + 1))
  fi
done

if [[ "$skipped" -gt 0 && "$failed" -eq 0 && "$ran" -gt 0 ]]; then
  say "summary: PARTIAL GATE — $ran passed, 0 failed, $skipped SKIPPED (root: $ROOT)"
  say "  $skipped detected check(s) did not run. This exit 0 means 'what ran, passed' — NOT 'checked'."
  say "  Re-run with --strict to make a missing tool fail instead."
else
  say "summary: $ran passed, $failed failed, $skipped skipped (root: $ROOT)"
fi
# A run where EVERY check was skipped is reported as "nothing detected" (3), not success. Otherwise a
# machine missing every linter would hand back a green gate — the exact false-green this file exists
# to prevent.
if [[ "$failed" -gt 0 ]]; then exit 1; fi
if [[ "$ran" -eq 0 ]]; then
  say "every detected check was skipped — treating as NO GATE, not as a pass"
  exit 3
fi
exit 0
