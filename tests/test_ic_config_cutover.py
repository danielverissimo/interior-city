import contextlib
import copy
import gzip
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import shutil
import tempfile
import types
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]
def load(name,path):
    spec=importlib.util.spec_from_file_location(name,path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
c=load('config_cutover_test',ROOT/'scripts/ic-config-cutover.py')
s=load('config_state_test',ROOT/'scripts/ic-config-state.py')
i=load('mansion_fixture_test',ROOT/'tests/test_ic_mansions_import.py')
r=load('release_config_test',ROOT/'scripts/release.py')

class Migration:
    def apply_schema(self,_):return {'schemaVersion':1}
    def verify_schema(self,_):return {'schemaVersion':1}

class ConfigCutoverTests(unittest.TestCase):
    def setUp(self):
        temp=tempfile.TemporaryDirectory();self.addCleanup(temp.cleanup)
        self.root=Path(temp.name).resolve();self.previous=self.root/'releases'/('a'*40);self.release=self.root/'releases'/('b'*40)
        self.previous.mkdir(parents=True)
        for relative,kind in s.FILES.items():
            path=self.previous/relative;path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps(kind()))
        legacy=self.previous/'resources/[scriptcore]/m_mansions';shutil.rmtree(legacy)
        i.MansionImportTests().fixture(legacy)
        (self.previous/'resources/[vrp]/vrp/cfg/groups.json').write_text('{"groups":[]}')
        (self.previous/'config').mkdir()
        (self.previous/'config/resources.cfg').write_text('ensure vrp\nensure inventory\nensure m_garage\nensure doorsv2\nensure m_mansions\nensure ic_admin\nensure mg_config_panel\n')
        (self.previous/'config/config.cfg').write_text('exec config/ic_admin.cfg\nexec config/resources.cfg\n')
        shutil.copytree(self.previous,self.release)
        # The previous generation does not contain the new resource at all.
        shutil.rmtree(self.previous/'resources/[scriptcore]/ic_mansions')
        (self.root/'state/manifests').mkdir(parents=True)
        r.manifest(self.previous,self.root/'state/manifests'/(self.previous.name+'.json'))
        groups=self.root/'state/resources/vrp/groups.json';groups.parent.mkdir(parents=True)
        groups.write_text('{"groups":[{"name":"Effective","config":{},"permissions":[]}]}')
        self.mounts=[{'Destination':'/server-data','Source':str(self.previous),'RW':True},
            {'Destination':'/server-data/resources/[vrp]/vrp/cfg/groups.json','Source':str(groups),'RW':True}]
        (self.root/'backups').mkdir()
        backup=self.root/'backups/vrp-fixture.sql.gz';backup.write_bytes(gzip.compress(b'fixture'))
        backup.with_name(backup.name+'.sha256').write_text(hashlib.sha256(backup.read_bytes()).hexdigest()+'  '+backup.name)
        self.migration=Migration()

    def preparing(self):
        return contextlib.ExitStack()

    def prepare(self):
        c.configure_candidate(self.release)
        with patch.object(c,'stopped_writers',return_value=('fixture',self.mounts)),\
             patch.object(c,'migration_context',return_value=(self.migration,object())),\
             patch.object(c,'rehearse_schema',return_value={'restored':True,'tableCountsMatch':True}):
            return c.prepare(self.root,self.previous,self.release)

    def test_candidate_render_only_changes_provider_selection_and_is_repeatable(self):
        c.configure_candidate(self.release);c.configure_candidate(self.release)
        c.validate_candidate(self.release)
        self.assertIn('ensure m_mansions',(self.previous/'config/resources.cfg').read_text())
        self.assertNotIn('ensure m_mansions',(self.release/'config/resources.cfg').read_text())
        self.assertIn('set ic_config_writes_enabled "true"',(self.release/'config/ic_config_runtime.cfg').read_text())
        self.assertLess((self.release/'config/config.cfg').read_text().index('ic_config_runtime'),(self.release/'config/config.cfg').read_text().index('resources.cfg'))

    def test_preparation_preserves_effective_mounts_imports_without_renewing_and_maps_rollback(self):
        report=self.prepare();self.assertEqual(report['stateFiles'],28);self.assertFalse(report['continuing'])
        groups=c.persistent_path(self.root,'resources/[vrp]/vrp/cfg/groups.json')
        self.assertEqual(json.loads(groups.read_text())['groups'][0]['name'],'Effective')
        own=c.persistent_path(self.root,'resources/[scriptcore]/ic_mansions/state-a.json')
        state=json.loads(own.read_text())['state'];self.assertEqual(state['mansions'][0]['iptuPaidUntil'],100)
        self.assertEqual(state['mansions'][0]['ownerId'],101)
        self.assertEqual(state['mansions'][0]['furniture'][0]['paidPrice'],750)
        control=self.root/'state/ic-config'
        self.assertFalse((control/'selection.json').exists())
        previous_overlay=(control/'overlays'/(self.previous.name+'.yaml')).read_text()
        self.assertNotIn('/server-data/resources/[scriptcore]/ic_mansions/',previous_overlay)
        self.assertEqual(previous_overlay.count('create_host_path: false'),26) # 25 files + report backup
        next_overlay=(control/'overlays'/(self.release.name+'.yaml')).read_text()
        self.assertEqual(next_overlay.count('create_host_path: false'),29)
        r.manifest(self.previous,self.root/'state/manifests'/(self.previous.name+'.json'),True)

    def test_forward_fix_keeps_new_ownership_and_never_reimports_legacy(self):
        self.prepare();c.mark_starting(self.root,self.release)
        third=self.root/'releases'/('c'*40);shutil.copytree(self.release,third)
        mounts=[]
        for relative in s.FILES:
            mounts.append({'Destination':'/server-data/'+relative,'Source':str(c.persistent_path(self.root,relative)),'RW':True})
        own=c.persistent_path(self.root,'resources/[scriptcore]/ic_mansions/state-a.json')
        envelope=json.loads(own.read_text());envelope['generation']=7;envelope['state']['mansions'][0]['iptuPaidUntil']=999
        payload=json.dumps(envelope['state'],ensure_ascii=False,separators=(',',':'));checksum=2166136261
        for byte in payload.encode():checksum=((checksum^byte)*16777619)&0xffffffff
        envelope.update(payload=payload,checksum=f'{checksum:08x}')
        own.write_text(json.dumps(envelope))
        with patch.object(c,'stopped_writers',return_value=('fixture',mounts)),\
             patch.object(c,'migration_context',return_value=(self.migration,object())),\
             patch.object(c,'rehearse_schema',return_value={'restored':True}):
            report=c.prepare(self.root,self.release,third)
        self.assertTrue(report['continuing']);self.assertEqual(report['counts']['generation'],7)
        self.assertEqual(json.loads(own.read_text())['state']['mansions'][0]['iptuPaidUntil'],999)
        receipt=json.loads((self.root/'state/ic-config'/(third.name+'.json')).read_text())
        self.assertFalse(receipt['legacyReimported'])

    def test_schema_failure_does_not_install_state_or_start_selection(self):
        c.configure_candidate(self.release)
        with patch.object(c,'stopped_writers',return_value=('fixture',self.mounts)),\
             patch.object(c,'migration_context',return_value=(self.migration,object())),\
             patch.object(c,'rehearse_schema',side_effect=c.CutoverError('Rehearsal failed')):
            with self.assertRaises(c.CutoverError):c.prepare(self.root,self.previous,self.release)
        self.assertFalse((self.root/'state/ic-config/selection.json').exists())
        self.assertFalse(c.persistent_path(self.root,'resources/[scriptcore]/ic_mansions/state-a.json').exists())

    def test_unknown_mounts_symlinks_and_immutable_drift_are_rejected(self):
        outsider=self.root/'outside.json';outsider.write_text('{}')
        with self.assertRaises(c.CutoverError):
            c.source_file(self.root,self.previous,'resources/[vrp]/vrp/cfg/groups.json',
                [{'Destination':'/server-data/resources/[vrp]/vrp/cfg/groups.json','Source':str(outsider)}])
        source=self.previous/'resources/[scriptcore]/inventory/config/shared.chests.json'
        source.unlink();source.symlink_to(outsider)
        with self.assertRaises(Exception):c.check_previous(self.root,self.previous)
        source.unlink();source.write_text('{}')
        (self.previous/'config/resources.cfg').write_text('ensure unreviewed_resource\n')
        with self.assertRaises(c.CutoverError):c.check_previous(self.root,self.previous)

    def test_runtime_requires_both_markers_all_persistent_mounts_and_no_legacy(self):
        self.prepare();c.mark_starting(self.root,self.release)
        mounts=[{'Destination':'/server-data/'+relative,'Source':str(c.persistent_path(self.root,relative)),'RW':True}for relative in s.FILES]
        info={'State':{'Running':True},'Mounts':mounts,'NetworkSettings':{'Networks':{'fixture':{'IPAddress':'127.0.0.1'}}}}
        markers={'ic_config':{'active':True,'schemaVersion':1,'provider':'ic_config'},'ic_mansions':{'active':True,'provider':'ic_mansions'}}
        class Response(io.StringIO):
            pass
        with patch.object(c,'container_info',return_value=('fixture',info)),patch.object(c,'markers',return_value=markers),\
             patch.object(c,'migration_context',return_value=(self.migration,object())),\
             patch.object(c.urllib.request,'urlopen',return_value=Response(json.dumps({'resources':['ic_config','ic_mansions','ic_admin']}))):
            self.assertTrue(c.verify_runtime(self.root,self.release)['runtimeVerified'])
        self.assertEqual(json.loads((self.root/'state/ic-config/selection.json').read_text())['phase'],'active')
        mounts.pop()
        with patch.object(c,'container_info',return_value=('fixture',info)),patch.object(c,'markers',return_value=markers),\
             patch.object(c,'migration_context',return_value=(self.migration,object())),\
             patch.object(c.urllib.request,'urlopen',return_value=Response(json.dumps({'resources':['ic_config','ic_mansions']}))):
            with self.assertRaises(c.CutoverError):c.verify_runtime(self.root,self.release)
