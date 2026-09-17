#!/usr/bin/env bash
# GH-654: offlane_candidates must name the paths that would fail the allowlist,
# and stay silent on the documented exemptions — before the bash verdict runs.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="$ROOT/utils/py:${PYTHONPATH:-}"
export REPO_ROOT="$ROOT"

python3 -B - <<'PY'
import importlib.util
import os
import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(os.environ['REPO_ROOT']).resolve()
sys.path.insert(0, str(ROOT / 'utils/py'))
spec = importlib.util.spec_from_file_location('rtl', ROOT / 'utils/py/rtl.py')
rtl = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rtl)


def make_worktree():
    wt = tempfile.mkdtemp(prefix='gh654-wt.')
    def git(*args):
        subprocess.run(['git', '-C', wt, *args], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    git('init', '-q')
    git('config', 'user.email', 'gh654@example.invalid')
    git('config', 'user.name', 'gh654')
    seed = pathlib.Path(wt, 'allowed-tracked.txt')
    seed.write_text('seed\n')
    relay = pathlib.Path(wt, 'marathon-system', 'gh654--p1')
    relay.mkdir(parents=True)
    (relay / 'RELAY.md').write_text('seed relay\n')
    git('add', 'allowed-tracked.txt', 'marathon-system/gh654--p1/RELAY.md')
    git('commit', '-q', '-m', 'seed')
    seed.write_text('mutated\n')                      # tracked, allowlisted, modified
    (relay / 'RELAY.md').write_text('seed relay\n### Round 1\n')  # tracked relay edit
    pathlib.Path(wt, 'allowed-new.txt').write_text('x\n')          # untracked, allowlisted
    pathlib.Path(wt, 'offlane-probe.txt').write_text('x\n')        # untracked, NOT allowlisted
    scratch = pathlib.Path(wt, '.relay-scratch'); scratch.mkdir()
    (scratch / 'v.log').write_text('x\n')                          # exempt (GH-91)
    tick = pathlib.Path(wt, '.tick', 'events'); tick.mkdir(parents=True)
    (tick / 'e.json').write_text('{}\n')                           # exempt
    logs = pathlib.Path(wt, 'relay-system', '2026-09-16'); logs.mkdir(parents=True)
    (logs / 'turn.md').write_text('x\n')                           # exempt (GH-266)
    return wt


ALLOW = 'allowed-tracked.txt,allowed-new.txt'
RELAY = 'marathon-system/gh654--p1/RELAY.md'


class OfflaneCandidates(unittest.TestCase):
    def setUp(self):
        self.wt = make_worktree()

    def tearDown(self):
        subprocess.run(['rm', '-rf', self.wt], check=True)

    def candidates(self, allow=ALLOW, relay=RELAY):
        return rtl.offlane_candidates(self.wt, allow, relay)

    def test_reports_only_the_offlane_path(self):
        found = self.candidates()
        self.assertEqual(found, ['offlane-probe.txt'],
                         'exactly the unallowlisted path must be named')

    def test_exemptions_are_silent(self):
        found = self.candidates()
        for quiet in ('.relay-scratch/v.log', '.tick/events/e.json',
                      'relay-system/2026-09-16/turn.md',
                      'allowed-new.txt', 'allowed-tracked.txt', RELAY):
            self.assertNotIn(quiet, found, f'{quiet} must not be reported')

    def test_relay_file_itself_is_never_offlane(self):
        self.assertNotIn(RELAY, self.candidates())

    # GH-654 follow-up: the shims pass the relay file ABSOLUTE; the sweep
    # compares worktree-relative porcelain. The normalized form must match.
    def test_absolute_relay_file_normalizes_to_relative(self):
        # real callers pass git-rev-parse output on both sides — abspath, no symlink resolution
        absolute = os.path.join(os.path.abspath(self.wt), RELAY)
        found = rtl.offlane_candidates(self.wt, ALLOW, absolute)
        self.assertNotIn(absolute, found, 'absolute relay path must not be reported')
        self.assertNotIn(RELAY, found, 'relay edit must not be reported')
        self.assertEqual(found, ['offlane-probe.txt'],
                         'the real off-lane file must still be the only finding')

    # GH-663 finding 4: a rename's SOURCE path must be checked too — a move
    # out of a non-allowlisted location may not stay silent.
    def test_rename_source_path_is_reported(self):
        # R porcelain entries require a TRACKED source — track the probe first.
        subprocess.run(['git', '-C', self.wt, 'add', 'offlane-probe.txt'], check=True)
        subprocess.run(['git', '-C', self.wt, 'commit', '-q', '-m', 'track probe'],
                       check=True, stdout=subprocess.DEVNULL)
        subprocess.run(['git', '-C', self.wt, 'mv', 'offlane-probe.txt',
                        'offlane-moved.txt'], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        found = self.candidates()
        self.assertIn('offlane-moved.txt', found, 'rename destination must be reported')
        self.assertIn('offlane-probe.txt', found, 'rename SOURCE must also be reported')

    def test_widening_the_allowlist_silences_a_path(self):
        self.assertEqual(self.candidates(allow=ALLOW + ',offlane-probe.txt'), [])

    # GH-654 root cause #2: the driver's artifact string is "a, b, c" (spaces
    # after commas). rtl_init's bare IFS split kept " b"/" c" leading spaces in
    # RTL_ALLOW, making every artifact after the first invisible to the sweep.
    # The Python bridge must hand the bash lib a TRIMMED csv.
    def test_normalized_allow_csv_trims_spaces(self):
        self.assertEqual(rtl.normalized_allow_csv(
            ' utils/py/turn_diagnostics.py, test/x.sh, validate.sh'),
            'utils/py/turn_diagnostics.py,test/x.sh,validate.sh')

    def test_spaced_csv_entries_match_porcelain(self):
        spaced = 'utils/py/turn_diagnostics.py, allowed-new.txt, allowed-tracked.txt'
        self.assertEqual(self.candidates(allow=spaced), ['offlane-probe.txt'],
                         'spaced csv entries must still silence their artifacts')

    # Mutation proof: a check that cannot fail is not a check. Rebinding the
    # exemption tuple to empty MUST make the same fixture report the exempt
    # dirs — proves the silence above is the code's doing, not the fixture's.
    def test_mutation_exemptions_are_load_bearing(self):
        saved = rtl.OFFLANE_EXEMPT
        rtl.OFFLANE_EXEMPT = ()
        try:
            found = self.candidates()
        finally:
            rtl.OFFLANE_EXEMPT = saved
        self.assertIn('.relay-scratch/', found, 'un-exempted scratch dir must surface')
        self.assertIn('.tick/', found, 'un-exempted tick dir must surface')
        self.assertIn('relay-system/', found, 'un-exempted transcript dir must surface')


if __name__ == '__main__':
    unittest.main()
PY
