"""Operational guards with temporary files; no remote host or production database."""
import contextlib,importlib.util,io,json,tempfile,unittest
from unittest.mock import patch
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
            with patch.object(c,'ensure_capacity'),contextlib.redirect_stdout(io.StringIO()):result=c.check_previous(root,old)
            self.assertEqual(len(result),2)
            (old/'server.cfg').write_text('unexpected code/configuration drift')
            with self.assertRaises(c.CutoverError):c.check_previous(root,old)

    def test_deduplication_preserves_code_state_and_modified_assets(self):
        import hashlib
        with tempfile.TemporaryDirectory() as directory:
            current=Path(directory)/'current';older=Path(directory)/'older';current.mkdir();older.mkdir()
            for root in (current,older):
                (root/'model.ydr').write_bytes(b'locked asset');(root/'server.lua').write_text('code untouched');(root/'player.json').write_text('state untouched')
            lock={'packages':[{'files':[{'path':'model.ydr','size':12,'sha256':hashlib.sha256(b'locked asset').hexdigest()}]}]}
            from unittest.mock import patch
            original=c.load
            with patch.object(c,'load',side_effect=lambda path,name:original(ROOT/'scripts/assets.py',name) if name=='asset_reuse' else original(path,name)):
                count,size=c.deduplicate_locked_assets(current,older,lock)
            self.assertEqual((count,size),(1,12))
            self.assertEqual((current/'model.ydr').stat().st_ino,(older/'model.ydr').stat().st_ino)
            self.assertEqual((older/'server.lua').read_text(),'code untouched')
            self.assertEqual((older/'player.json').read_text(),'state untouched')
            (older/'model.ydr').unlink();(older/'model.ydr').write_bytes(b'owner modification')
            with patch.object(c,'load',side_effect=lambda path,name:original(ROOT/'scripts/assets.py',name) if name=='asset_reuse' else original(path,name)):
                self.assertEqual(c.deduplicate_locked_assets(current,older,lock),(0,0))
            self.assertEqual((older/'model.ydr').read_bytes(),b'owner modification')

    def test_reports_are_private_and_atomic(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'report.json';c.write(path,{'verified':True})
            self.assertEqual(path.stat().st_mode&0o777,0o600)
            self.assertEqual(json.loads(path.read_text()),{'verified':True})
            self.assertFalse(path.with_suffix('.next').exists())

    def test_only_known_mutable_dismantling_json_can_drift(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);old=root/'releases'/('a'*40);old.mkdir(parents=True)
            (root/'state/manifests').mkdir(parents=True)
            config=old/'resources/[scripts]/m_desmanche/config.json';config.parent.mkdir(parents=True)
            config.write_text('{"settings":{},"desmanches":[]}')
            r.manifest(old,root/'state/manifests'/('a'*40+'.json'))
            config.write_text('{"settings":{},"desmanches":[{"name":"Edited in city"}]}')
            with patch.object(c,'ensure_capacity'),contextlib.redirect_stdout(io.StringIO()):self.assertEqual(c.check_previous(root,old),['resources/[scripts]/m_desmanche/config.json'])
            config.write_text('[]')
            with self.assertRaises(c.CutoverError):c.check_previous(root,old)

    def test_boot_configuration_selects_new_provider_without_starting_legacy(self):
        cfg=(ROOT/'config/ic_admin.cfg').read_text();resources=(ROOT/'config/resources.cfg').read_text()
        self.assertIn('setr ic_admin_mode "active"',cfg)
        self.assertIn('setr ic_admin_service_resource "ic_admin"',cfg)
        self.assertNotRegex(resources,r'(?m)^\s*(?:ensure|start)\s+m_paineladm_v2\s*$')
        self.assertIn('ensure mg_config_panel',resources)
        self.assertIn('ensure ic_admin',resources)

    def test_runtime_verification_waits_for_database_readiness(self):
        from types import SimpleNamespace
        import json
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);release=root/'releases'/('a'*40);release.mkdir(parents=True);(root/'state').mkdir()
            report=root/'state'/('ic-admin-cutover-'+release.name+'.json');report.write_text('{}')
            info={'resources':['ic_admin','mg_config_panel','vrp','inventory']}
            class Response(io.StringIO):
                def __enter__(self):return self
                def __exit__(self,*args):self.close()
            ready={'active':True,'schemaVersion':2,'provider':'ic_admin','legacyState':'stopped','mode':'active'}
            with patch.object(c,'containers',return_value={'fxserver':'fake'}),patch.object(c,'run',return_value=json.dumps([{'NetworkSettings':{'Networks':{'test':{'IPAddress':'127.0.0.1'}}}}])),patch.object(c.urllib.request,'urlopen',side_effect=lambda *args,**kwargs:Response(json.dumps(info))),patch.object(c,'operational_marker',side_effect=[None,ready]) as probe,patch.object(c.time,'sleep'),contextlib.redirect_stdout(io.StringIO()):
                c.verify_runtime(root,release)
            self.assertEqual(probe.call_count,2)
            self.assertTrue(json.loads(report.read_text())['runtimeVerified'])

    def test_environment_recovery_preserves_recognized_state_and_refuses_unknown_units(self):
        self.assertIsNone(c.normalize_environment({'values':{}}))
        self.assertEqual(c.normalize_environment({'values':{'environment_state':'{"weather":"RAIN","hour":17,"freezeTime":true}'}})['hour'],17)
        self.assertEqual(c.normalize_environment({'values':{'weather':'CLEAR','hour':8,'freezeTime':1}}),{'weather':'CLEAR','hour':8,'freezeTime':True})
        with self.assertRaises(c.CutoverError):c.normalize_environment({'values':{'time':800}})
        with self.assertRaises(c.CutoverError):c.normalize_environment({'values':{},'unsupported':1})

    def test_kvp_settings_recover_permissions_even_when_environment_json_exists(self):
        with tempfile.TemporaryDirectory() as directory:
            captured=Path(directory)
            (captured/'panel_permissions.json').write_text('')
            environment={'weather':'RAIN','hour':17,'rotating':True}
            (captured/'environment_state.json').write_text(json.dumps(environment))
            permissions={'view_server':{'admin':False,'moderador':True,'suporte':False}}
            result=c.merge_legacy_kvp({'keyCount':3,'values':{
                'panel_permissions':json.dumps(permissions),'logs_config':'{"webhooks":[]}',
                'environment_state':json.dumps(environment)}},captured)
            self.assertEqual(json.loads((captured/'panel_permissions.json').read_text()),permissions)
            self.assertEqual(json.loads((captured/'logs_config.json').read_text()),{'webhooks':[]})
            self.assertEqual(result['permissionRecords'],1)
            self.assertEqual(result['namespaceKeys'],3)
            self.assertEqual((captured/'panel_permissions.json').stat().st_mode&0o777,0o600)

    def test_kvp_conflicts_and_unknown_records_block_before_writing(self):
        with tempfile.TemporaryDirectory() as directory:
            captured=Path(directory);path=captured/'panel_permissions.json'
            path.write_text('{"view_server":{"admin":true}}')
            before=path.read_bytes()
            with self.assertRaises(c.CutoverError):c.merge_legacy_kvp({'values':{'panel_permissions':'{"view_server":{"admin":false}}','logs_config':'{"webhooks":[]}'}},captured)
            self.assertEqual(path.read_bytes(),before)
            self.assertFalse((captured/'logs_config.json').exists())
            with self.assertRaises(c.CutoverError):c.merge_legacy_kvp({'values':{},'unsupported':1},captured)
            with self.assertRaises(c.CutoverError):c.merge_legacy_kvp({'values':{'panel_permissions':'[]'}},captured)

    def test_equivalent_permission_wrappers_do_not_conflict(self):
        with tempfile.TemporaryDirectory() as directory:
            captured=Path(directory);permissions={'view_server':{'admin':True}}
            (captured/'panel_permissions.json').write_text(json.dumps({'actions':permissions}))
            c.merge_legacy_kvp({'values':{'panel_permissions':json.dumps(permissions)}},captured)
            self.assertEqual(json.loads((captured/'panel_permissions.json').read_text()),permissions)
