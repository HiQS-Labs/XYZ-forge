#!/usr/bin/env python3
"""hosted_lane_publish.py — commit the declared reconciliation artifacts and push them (GH-740).

The last real step of .github/workflows/wave-reconcile.yml. It used to be inline Python whose one
`git push origin HEAD:development` was rejected whenever a merge landed on development during the
~70-minute run — and the rejection threw away the qualification receipts with everything else, so
the next run qualified the same landings again (a receipt only counts once it is committed on
HEAD; see wave_reconcile.committed_qualifications). Three such collisions in five days (09-18 ×2,
09-21) is what this file exists for.

Fast path (no race) is exactly what the inline step did: validate every changed path against the
allowlist, `git add` those paths explicitly, commit once, push once.

Race path (push rejected) and the commit carried receipts:
  1. fetch; `reset --hard origin/development` — the stale transitions are DISCARDED, never rebased
     or restored over the racer's ledger (the SQLite DB is regenerated, not merged);
  2. lift only the receipt FILES out of the discarded commit onto the fresh head
     (`git checkout <T> -- <receipt paths>`; a `wave-<tested>` folder is unique to this run, so
     nothing can collide), commit, push — up to 3 attempts, receipts-only, no judgment;
  3. recompute ONCE on the clean fresh head: re-run the reconcile step's own argv plus
     `--only-receipted --skip-pull`, with this run's landings named explicitly (the `pr` /
     `landing_commit` identities in the receipts just published, coalesced into the argv's own
     `--pr`/`--commit` groups — argparse `nargs="+"` overwrites a repeated option). With the receipts
     on HEAD the retry cannot run the suite; newcomers (the racer) are deferred to their own run.
     Validate, commit, push. A second rejection exits 1 naming the racing head — the receipts are
     already published, so nothing expensive is lost.
Race path without receipts: exit 1 immediately (nothing expensive at stake; the next run recomputes).

Every handled recovery failure prints one `hosted-lane-publish: ERROR — …` line on stderr — the
contract hosted_lane_report.py reads when the publish step is the one that failed (GH-741). The
allowlist refusal keeps its historical `Refusing undeclared reconciliation artifacts` text, and an
unexpected git error surfaces as a traceback; the report falls back to the log's last line for those.
stdlib + git only; never force-pushes; the allowlist is the one the inline step had, unchanged.
"""
import argparse
import json
import os
import re
import shlex
import subprocess
import sys

ERROR_PREFIX = "hosted-lane-publish: ERROR — "
BOT_NAME = "github-actions[bot]"
BOT_EMAIL = "41898282+github-actions[bot]@users.noreply.github.com"
BRANCH = "development"
RECEIPT_ATTEMPTS = 3

# --- the declared-artifact allowlist, verbatim from the former inline step ------------------------
EXACT = {'releases.db', 'releases.sql', 'ROADMAP.md',
         'RELEASES-PREVIEW.html', 'LEADERBOARD.html', 'LEADERBOARD.md'}
# GH-721: 1-INBOX is the deletion side of a closed-issue capture promotion (GH-698 item 2);
# keep this alternation equal to wave_reconcile.RECONCILE_FOLDERS plus the two destinations.
DOC = r'PROJECT/(?:1-INBOX|2-WORKING|3-COMPLETED|4-MISC)/(?:GH-)?[0-9]+-[^/]+\.md'
PLAN = r'(?:PROJECT/2-WORKING/)?MARATHON-PLAN-[0-9]{4}-[0-9]{2}-[0-9]{2}\.md'
RECEIPT = r'TESTS-RESULTS/[0-9]{4}-[0-9]{2}-[0-9]{2}\+GH-591/wave-[0-9a-f]{40}/(?:provenance|validation)\.jsonl'


def log(message):
    print(f"hosted-lane-publish: {message}", flush=True)


def fail(message):
    print(ERROR_PREFIX + message, file=sys.stderr, flush=True)
    raise SystemExit(1)


def git(*args, check=True):
    return subprocess.run(['git', *args], capture_output=True, text=True, check=check)


def changed_paths():
    """Every path the reconcile step touched, deletions included (--no-renames makes them explicit)."""
    out = git('diff', '--name-only', '--no-renames', '-z', 'HEAD').stdout
    changed = set(filter(None, out.split('\0')))
    changed.update(filter(None, git('ls-files', '--others', '--exclude-standard', '-z').stdout.split('\0')))
    return sorted(changed)


def declared_paths(paths):
    """The allowlist: refuse anything the bot may not commit. Same rules, same order, as before."""
    unexpected = [p for p in paths if p not in EXACT and not re.fullmatch(DOC, p)
                  and not re.fullmatch(PLAN, p) and not re.fullmatch(RECEIPT, p)]
    if unexpected:
        raise SystemExit('Refusing undeclared reconciliation artifacts: ' + repr(unexpected))
    return paths


def receipt_paths(paths):
    return [p for p in paths if re.fullmatch(RECEIPT, p)]


def commit(paths, message):
    # Explicit paths only; a downstream generator cannot widen the bot commit.
    git('add', '-A', '--', *paths)
    git('config', 'user.name', BOT_NAME)
    git('config', 'user.email', BOT_EMAIL)
    git('commit', '-q', '-m', message)
    return git('rev-parse', 'HEAD').stdout.strip()


def push():
    """True when the fast-forward push landed; False on a non-fast-forward rejection; raise otherwise."""
    result = git('push', 'origin', f'HEAD:{BRANCH}', check=False)
    if result.returncode == 0:
        return True
    text = result.stderr + result.stdout
    if '[rejected]' in text or 'fetch first' in text or 'non-fast-forward' in text:
        print(text, end='', file=sys.stderr, flush=True)
        return False
    fail(f"git push failed for a reason other than a rejected fast-forward: {text.strip()}")


def remote_head():
    git('fetch', 'origin', BRANCH)
    return git('rev-parse', f'origin/{BRANCH}').stdout.strip()


def receipt_targets(receipts):
    """(pr numbers, landing commits) named by the provenance entries in the receipt files just published."""
    prs, commits = [], []
    for path in receipts:
        if not path.endswith('provenance.jsonl'):
            continue
        for line in open(path, encoding='utf-8'):
            line = line.strip()
            if not line:
                continue
            entry = json.loads(line)
            if entry.get('artifact_kind') == 'commit' and re.fullmatch(r'[0-9a-f]{40}', entry.get('landing_commit') or ''):
                commits.append(entry['landing_commit'])
            elif type(entry.get('pr')) is int and entry['pr'] > 0:
                prs.append(str(entry['pr']))
            else:
                fail(f"receipt entry in {path} names neither a PR nor a landing commit; refusing to guess the retry targets")
    return prs, commits


def retry_argv(reconcile_args, prs, commits):
    """The reconcile step's own argv with --pr/--commit COALESCED (a repeated option would overwrite)
    plus --only-receipted --skip-pull. Everything else is retained verbatim, in order."""
    tokens = shlex.split(reconcile_args)
    kept, orig_prs, orig_commits = [], [], []
    i = 0
    while i < len(tokens):
        tok = tokens[i]
        if tok in ('--pr', '--commit'):
            bucket = orig_prs if tok == '--pr' else orig_commits
            i += 1
            while i < len(tokens) and not tokens[i].startswith('-'):
                bucket.append(tokens[i])
                i += 1
            continue
        kept.append(tok)
        i += 1
    argv = list(kept)
    all_prs = list(dict.fromkeys(orig_prs + prs))
    all_commits = list(dict.fromkeys(orig_commits + commits))
    if all_prs:
        argv += ['--pr', *all_prs]
    if all_commits:
        argv += ['--commit', *all_commits]
    for flag in ('--only-receipted', '--skip-pull'):
        if flag not in argv:
            argv.append(flag)
    return argv


def recompute(argv, reconcile_cmd):
    """Re-run the reconciler once on the clean fresh head. Its own diagnostics stay in this step's log."""
    fingerprint = os.path.join('.tick', 'marathon-plan.fingerprint')
    if os.path.exists(fingerprint):
        os.remove(fingerprint)  # the reset reverted the plan file; force the planner to regenerate it
    log('recompute: ' + ' '.join(shlex.quote(a) for a in [*reconcile_cmd, *argv]))
    result = subprocess.run([*reconcile_cmd, *argv], capture_output=True, text=True, check=False)
    print(result.stdout, end='', flush=True)
    print(result.stderr, end='', file=sys.stderr, flush=True)
    if result.returncode != 0:
        errors = [l for l in (result.stdout + result.stderr).splitlines() if l.startswith('wave-reconcile: ERROR — ')]
        detail = errors[-1] if errors else f"exit {result.returncode}"
        fail(f"recompute failed after the receipts were published: {detail}")


# Protected integration branches use the same allowlist and writer, with PR review.
RECONCILE_PREFIX = 'automation/reconcile-'


def pending_publication(repo):
    from coverage_admission import paged
    return [p for p in paged(f'repos/{repo}/pulls?state=open&base=development&per_page=100')
            if p.get('user', {}).get('id') == 41898282
            and p.get('head', {}).get('ref', '').startswith(RECONCILE_PREFIX)]


def publication_landing(repo_root, pr):
    """No label/title exemption: verify author, namespace AND complete landed diff."""
    if (pr.get('user', {}).get('id') != 41898282
            or not pr.get('head', {}).get('ref', '').startswith(RECONCILE_PREFIX)):
        return False
    sha = pr.get('merge_commit_sha', '')
    if not re.fullmatch(r'[0-9a-f]{40}', sha):
        return False
    result = subprocess.run(['git', '-C', str(repo_root), 'diff', '--no-renames',
                             '--name-only', '-z', sha + '^1', sha], capture_output=True, text=True)
    if result.returncode:
        return False
    from coverage_admission import is_packet_path
    paths = [p for p in result.stdout.split('\0') if p and not is_packet_path(p)]
    if not paths:
        return False
    try:
        declared_paths(paths)
    except SystemExit:
        return False
    return True


def publish_review(paths, repo):
    """Retain qualified artifacts on a reviewable branch; never direct-push fallback."""
    from pathlib import Path
    from coverage_admission import PACKET_DIR, manifest, packet, open_pr
    import uuid
    # Recheck the original allowlist before admitting the generated packet.
    declared_paths(paths)
    if pending_publication(repo):
        fail('reconciliation PR already pending; retain local artifacts and await its review')
    base = git('rev-parse', 'HEAD').stdout.strip()
    git('add', '-A', '--', *paths)
    root = Path.cwd()
    merge_base, _, rows, record_path = manifest(root, base, 'INDEX')
    if record_path is not None:
        fail('unexpected staged admission record before publication')
    record_path = f'{PACKET_DIR}/{uuid.uuid4().hex}.json'
    decision = dict(outcome='no-add', behavior='Publish existing qualification receipts and lifecycle state',
                    existing_coverage='Existing qualifying gate receipts; no executable test changes',
                    reason='Required review replaces direct integration push on protected development',
                    red_evidence='Publisher allowlist refuses code/test changes',
                    cost='Zero new automated tests; prior qualifying run retained in receipts',
                    issue='https://github.com/HiQS-Labs/XYZ-forge/issues/805')
    target = root / record_path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(packet(merge_base, rows, decision), indent=2, sort_keys=True) + '\n')
    full = commit([*paths, record_path], 'chore: reconcile merged development work')
    branch = RECONCILE_PREFIX + full[:16]
    git('push', 'origin', f'HEAD:refs/heads/{branch}')
    pr = open_pr(repo, branch, full, 'chore: review qualified reconciliation artifacts',
                 'Lifecycle/receipt publication from the hosted reconciler. No new tests. '
                 'Review the generated coverage decision and allowlisted diff. No automatic merge.')
    log('reconciliation awaits operator review: ' + pr['html_url'])
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--reconcile-args', default='',
                        help='the argv the reconcile step ran (RECONCILE_ARGS); reused for the one bounded recompute')
    parser.add_argument('--reconcile-cmd', default='python3 utils/py/wave_reconcile.py',
                        help='the reconciler command (tests substitute a stub)')
    parser.add_argument('--protected', action='store_true', help='publish via operator-reviewed PR; no direct push fallback')
    parser.add_argument('--repo', default=os.environ.get('GITHUB_REPOSITORY', ''))
    args = parser.parse_args(argv)
    reconcile_cmd = shlex.split(args.reconcile_cmd)

    paths = declared_paths(changed_paths())
    if not paths:
        print('Nothing to commit')
        return 0
    if args.protected:
        if not args.repo:
            fail('--protected requires --repo')
        return publish_review(paths, args.repo)
    receipts = receipt_paths(paths)
    full = commit(paths, 'chore: reconcile merged development work')
    if push():
        log(f'pushed {len(paths)} declared path(s) as {full[:12]}')
        return 0

    # --- raced --------------------------------------------------------------------------------------
    moved = remote_head()
    if not receipts:
        fail(f"push rejected; origin/{BRANCH} moved to {moved[:12]}; no receipts this run — the next run recomputes cheaply")
    log(f'push rejected — origin/{BRANCH} moved to {moved[:12]}; discarding {full[:12]}, publishing its {len(receipts)} receipt file(s) first')
    tested = re.search(r'wave-([0-9a-f]{40})/', receipts[0]).group(1)
    for attempt in range(1, RECEIPT_ATTEMPTS + 1):
        git('reset', '--hard', f'origin/{BRANCH}')
        git('checkout', full, '--', *receipts)
        receipt_commit = commit(receipts, f'chore: retain qualification receipts for {tested}')
        if push():
            log(f'receipts published as {receipt_commit[:12]} (attempt {attempt})')
            break
        moved = remote_head()
    else:
        fail(f"receipts push rejected {RECEIPT_ATTEMPTS} times; origin/{BRANCH} is at {moved[:12]}")

    # --- one recompute, bounded: --only-receipted cannot run the suite -------------------------------
    prs, commits = receipt_targets(receipts)
    recompute(retry_argv(args.reconcile_args, prs, commits), reconcile_cmd)
    paths = declared_paths(changed_paths())
    if not paths:
        log('recompute produced nothing further to commit')
        return 0
    second = commit(paths, 'chore: reconcile merged development work')
    if push():
        log(f'pushed recomputed transitions as {second[:12]}')
        return 0
    moved = remote_head()
    fail(f"push rejected after recompute; origin/{BRANCH} moved to {moved[:12]}; receipts {receipt_commit[:12]} are published, nothing expensive was lost")


if __name__ == '__main__':
    sys.exit(main())
