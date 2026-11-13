"""Exercise the SSH boundary and exact-master gate without SSH, sudo or Docker."""
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('actions_receiver', ROOT / 'scripts/ci/uriel-actions.py')
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)
SHA = 'a' * 40


class ActionsDeployTests(unittest.TestCase):
    def test_requests_accept_only_three_fixed_operations(self):
        self.assertEqual(gate.parse_request(['status']), ('status', None))
        for mode in ['check', 'deploy']:
            self.assertEqual(gate.parse_request([mode, SHA]), (mode, SHA))
        for args in [[], ['bash'], ['status', SHA], ['deploy', SHA + ';id'],
                     ['deploy', '../archive'], ['deploy', 'A' * 40], ['check', SHA, '--root=/']]:
            with self.subTest(args=args), self.assertRaises(gate.Refused):
                gate.parse_request(args)

    def test_forced_ssh_command_rejects_shell_upload_and_forwarding_requests(self):
        for request in ['', 'bash', 'scp -t /tmp', 'deploy ' + SHA + '; id', 'check ' + SHA + ' extra']:
            result = subprocess.run(['bash', str(ROOT / 'scripts/ci/uriel-ssh-command.sh')],
                                    env=dict(os.environ, SSH_ORIGINAL_COMMAND=request),
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)

    def test_runner_rejects_other_repositories_branches_and_prs_before_ssh(self):
        baseline = dict(os.environ, GITHUB_REPOSITORY='danielverissimo/interior-city',
                        GITHUB_REF='refs/heads/master', GITHUB_EVENT_NAME='push')
        for values in [{'GITHUB_REPOSITORY': 'someone/fork'}, {'GITHUB_REF': 'refs/heads/topic'},
                       {'GITHUB_EVENT_NAME': 'pull_request'}, {'GITHUB_EVENT_NAME': 'pull_request_target'}]:
            result = subprocess.run(['bash', str(ROOT / 'scripts/ci/runner-deploy.sh'), SHA],
                                    env={**baseline, **values}, capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)

    def test_current_release_requires_exact_managed_symlink(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            with self.assertRaises(gate.Refused):
                gate.current_release(root)
            release = root / 'releases' / SHA
            release.mkdir(parents=True)
            (root / 'current').symlink_to(release)
            self.assertEqual(gate.current_release(root), release)
            (root / 'current').unlink()
            (root / 'current').symlink_to(root)
            with self.assertRaises(gate.Refused):
                gate.current_release(root)

    def test_stale_sha_is_rejected_before_creating_an_archive(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            (root / 'repository.git').mkdir()
            archive = root / 'release.tar'
            with patch.object(gate, 'run', side_effect=[b'', ('b' * 40 + '\n').encode()]) as run:
                with self.assertRaises(gate.Refused):
                    gate.master_archive(SHA, archive, io.BytesIO(), root)
            self.assertFalse(archive.exists())
            self.assertIn('+refs/heads/master:refs/heads/master', run.call_args_list[0].args[0])

    def test_status_exposes_only_release_and_phase(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            release = root / 'releases' / SHA
            release.mkdir(parents=True)
            (root / 'current').symlink_to(release)
            control = root / 'state/ic-config'
            control.mkdir(parents=True)
            (control / 'selection.json').write_text(json.dumps({'phase': 'active', 'private': 'fixture'}))
            self.assertEqual(gate.status(root), {'current': SHA, 'configPhase': 'active'})

    def test_check_mode_never_runs_installer_or_changes_live_link(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            previous = root / 'releases' / ('b' * 40)
            previous.mkdir(parents=True)
            (root / 'current').symlink_to(previous)
            control = root / 'control'
            control.mkdir()
            class Extractor:
                @staticmethod
                def extract(archive, target):
                    (target / 'scripts').mkdir(parents=True)
            with patch.object(gate, 'master_archive', return_value=['git']), \
                 patch.object(gate, 'run', return_value=b''), \
                 patch.object(gate, 'load', return_value=Extractor()), \
                 patch.object(gate, 'preflight', return_value={'stateFiles': 29}), \
                 patch.object(gate.subprocess, 'run') as process:
                report = gate.execute('check', SHA, io.BytesIO(), root, control)
            self.assertEqual(report['mode'], 'check')
            self.assertEqual(gate.current_release(root), previous)
            process.assert_not_called()

    def test_installer_failure_never_reports_success(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            previous = root / 'releases' / ('b' * 40)
            previous.mkdir(parents=True)
            (root / 'current').symlink_to(previous)
            control = root / 'control'
            control.mkdir()
            class Extractor:
                @staticmethod
                def extract(archive, target):
                    (target / 'scripts').mkdir(parents=True)
            with patch.object(gate, 'master_archive', return_value=['git']), \
                 patch.object(gate, 'run', return_value=b''), \
                 patch.object(gate, 'load', return_value=Extractor()), \
                 patch.object(gate, 'preflight', return_value={}), \
                 patch.object(gate.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1)):
                with self.assertRaises(gate.Refused):
                    gate.execute('deploy', SHA, io.BytesIO(), root, control)


if __name__ == '__main__':
    unittest.main()
