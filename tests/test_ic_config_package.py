import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('candidate_package_test',ROOT/'scripts/prepare-ic-config-release.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

class CandidatePackageTests(unittest.TestCase):
    def test_private_candidate_keeps_user_index_branch_and_unrelated_edit_unchanged(self):
        with tempfile.TemporaryDirectory()as tmp:
            parent=Path(tmp).resolve();repo=parent/'repo';repo.mkdir()
            def git(*args):
                result=subprocess.run(['git',*args],cwd=repo,capture_output=True,text=True)
                self.assertEqual(result.returncode,0,result.stderr);return result.stdout.strip()
            git('init','-q');git('config','user.name','Fixture');git('config','user.email','fixture@example.invalid')
            for directory in('scripts','config','resources/[scriptcore]/ic_mansions'):(repo/directory).mkdir(parents=True)
            for name in('release.py','ic-config-cutover.py','prepare-ic-config-release.py'):
                shutil.copyfile(ROOT/'scripts'/name,repo/'scripts'/name)
            for name in('state-a.json','state-b.json'):
                shutil.copyfile(ROOT/'resources/[scriptcore]/ic_mansions'/name,repo/'resources/[scriptcore]/ic_mansions'/name)
            (repo/'config/config.cfg').write_text('exec config/resources.cfg\n')
            (repo/'config/resources.cfg').write_text('ensure m_mansions\nensure mg_config_panel\n')
            (repo/'README.md').write_text('base\n');(repo/'unrelated.txt').write_text('original\n')
            git('add','.');git('commit','-qm','fixture baseline')
            head=git('rev-parse','HEAD');branch=git('symbolic-ref','HEAD')
            (repo/'unrelated.txt').write_text('user staged edit\n');git('add','unrelated.txt')
            (repo/'README.md').write_text('candidate documentation\n')
            index=(repo/'.git/index').read_bytes()
            with patch.object(m,'ROOT',repo):report=m.prepare(parent/'candidate')
            self.assertEqual(git('rev-parse','HEAD'),head);self.assertEqual(git('symbolic-ref','HEAD'),branch)
            self.assertEqual((repo/'.git/index').read_bytes(),index)
            self.assertEqual((repo/'unrelated.txt').read_text(),'user staged edit\n')
            self.assertIn('unrelated.txt',report['excludedTrackedChanges'])
            self.assertEqual(git('show',report['candidateCommit']+':unrelated.txt'),'original')
            self.assertEqual(git('show',report['candidateCommit']+':README.md'),'candidate documentation')
            self.assertEqual((parent/'candidate').stat().st_mode&0o777,0o700)
            self.assertEqual((parent/'candidate/release.tar.gz').stat().st_mode&0o777,0o600)
            self.assertFalse(report['hostContacted']);self.assertFalse(report['deployed'])
            preview=json.loads((parent/'candidate/provider-preview-manifest.json').read_text())
            self.assertIn('config/ic_config_runtime.cfg',preview)
            with tarfile.open(parent/'candidate/release.tar.gz')as archive:
                self.assertNotIn('config/ic_config_runtime.cfg',archive.getnames())
                self.assertEqual(archive.extractfile('README.md').read(),b'candidate documentation\n')
            # A user may have committed unrelated work after the deployed release.
            # An explicit deployed baseline must still exclude that work from this release.
            git('commit','-qm','user unrelated commit')
            committed_head=git('rev-parse','HEAD');committed_index=(repo/'.git/index').read_bytes()
            (repo/'README.md').write_text('next candidate documentation\n')
            with patch.object(m,'ROOT',repo):baseline_report=m.prepare(parent/'baseline-candidate',base_commit=head)
            self.assertEqual(baseline_report['baseCommit'],head)
            self.assertEqual(baseline_report['sourceHead'],committed_head)
            self.assertIn('unrelated.txt',baseline_report['excludedTrackedChanges'])
            self.assertEqual(git('show',baseline_report['candidateCommit']+':unrelated.txt'),'original')
            self.assertEqual((repo/'unrelated.txt').read_text(),'user staged edit\n')
            self.assertEqual(git('rev-parse','HEAD'),committed_head)
            self.assertEqual((repo/'.git/index').read_bytes(),committed_index)
            self.assertEqual(git('symbolic-ref','HEAD'),branch)
