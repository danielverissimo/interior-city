"""Operational guards with temporary files; no remote host or production database."""
import contextlib,importlib.util,io,json,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def load(name,path):
    spec=importlib.util.spec_from_file_location(name,path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
c=load('ic_cutover',ROOT/'scripts/ic-admin-cutover.py')
r=load('ic_release',ROOT/'scripts/release.py')
class CutoverTests(unittest.TestCase):
    def test_only_legacy_mutable_data_and_known_generated_cache_can_drift(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);old=root/'releases'/('a'*40);old.mkdir(parents=True)
            (root/'state/manifests').mkdir(parents=True)
            (old/'server.cfg').write_text('safe fixture')
            data=old/'resources/[scriptcore]/m_paineladm_v2/locations.json';data.parent.mkdir(parents=True);data.write_text('[]')
            r.manifest(old,root/'state/manifests'/('a'*40+'.json'))
            data.write_text('[{"name":"Changed by runtime"}]')
            cache=old/'scripts/__pycache__/release.cpython-314.pyc';cache.parent.mkdir(parents=True);cache.write_bytes(b'generated')
            with contextlib.redirect_stdout(io.StringIO()):result=c.check_previous(root,old)
            self.assertEqual(len(result),2)
            (old/'server.cfg').write_text('unexpected code/configuration drift')
            with self.assertRaises(c.CutoverError):c.check_previous(root,old)

    def test_reports_are_private_and_atomic(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'report.json';c.write(path,{'verified':True})
            self.assertEqual(path.stat().st_mode&0o777,0o600)
            self.assertEqual(json.loads(path.read_text()),{'verified':True})
            self.assertFalse(path.with_suffix('.next').exists())

    def test_boot_configuration_selects_new_provider_without_starting_legacy(self):
        cfg=(ROOT/'config/ic_admin.cfg').read_text();resources=(ROOT/'config/resources.cfg').read_text()
        self.assertIn('setr ic_admin_mode "active"',cfg)
        self.assertIn('setr ic_admin_service_resource "ic_admin"',cfg)
        self.assertNotRegex(resources,r'(?m)^\s*(?:ensure|start)\s+m_paineladm_v2\s*$')
        self.assertIn('ensure mg_config_panel',resources)
        self.assertIn('ensure ic_admin',resources)

    def test_environment_recovery_preserves_recognized_state_and_refuses_unknown_units(self):
        self.assertIsNone(c.normalize_environment({'values':{}}))
        self.assertEqual(c.normalize_environment({'values':{'environment_state':'{"weather":"RAIN","hour":17,"freezeTime":true}'}})['hour'],17)
        self.assertEqual(c.normalize_environment({'values':{'weather':'CLEAR','hour':8,'freezeTime':1}}),{'weather':'CLEAR','hour':8,'freezeTime':True})
        with self.assertRaises(c.CutoverError):c.normalize_environment({'values':{'time':800}})
        with self.assertRaises(c.CutoverError):c.normalize_environment({'values':{},'unsupported':1})
