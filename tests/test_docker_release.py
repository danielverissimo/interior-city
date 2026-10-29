import importlib.util
import io
import json
import os
import re
from pathlib import Path
import subprocess
import shutil
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def module(name, filename):
    spec = importlib.util.spec_from_file_location(name, ROOT/'scripts'/filename)
    result = importlib.util.module_from_spec(spec); spec.loader.exec_module(result)
    return result


c = module('configuration', 'configure-secrets.py')
r = module('release', 'release.py')
a = module('asset_normalization', 'assets.py')
w = module('web_assets', 'web-assets.py')


class DockerReleaseTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name); self.private = self.root/'secrets'
        c.initialize(self.private)
        self.schema = ROOT/'config/resource-secrets.schema.json'
        self.license = 'cfxk_' + 'fixture_not_a_real_license'
        c.write_private(self.private/'cfx_license', self.license)

    def test_init_preserves_existing_credentials_and_private_parent(self):
        password = (self.private/'db_app_password').read_bytes()
        c.initialize(self.private)
        self.assertEqual(password, (self.private/'db_app_password').read_bytes())
        self.assertEqual((self.private/'cfx_license').read_text(), self.license)
        self.assertEqual(self.private.stat().st_mode & 0o777, 0o700)

    def test_render_and_entrypoint_do_not_publish_resource_secrets(self):
        value = 'fixture_token_not_valid_anywhere'
        c.write_private(self.private/'resource_secrets.json', json.dumps({'ic_secret_smartphone_token':value}))
        c.render(self.private, self.schema)
        result, cfg = self.entrypoint()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('set ic_secret_smartphone_token "'+value+'"', cfg)
        self.assertNotIn('setr ', cfg); self.assertNotIn('sets ', cfg)
        self.assertNotIn(value, result.stdout+result.stderr)
        self.assertIn('multipleStatements=true', cfg)

    def entrypoint(self):
        server = self.root/'server'; server.mkdir(exist_ok=True)
        run = self.root/'run.sh'; run.write_text('#!/bin/sh\nexit 0\n'); run.chmod(0o755)
        source = (ROOT/'docker/fxserver/entrypoint.sh').read_text()
        source = source.replace('/run/secrets/', str(self.private)+'/').replace('/server-data', str(server)).replace('/opt/fxserver/run.sh', str(run))
        script = self.root/'entrypoint.sh'; script.write_text(source)
        env = dict(os.environ, FIVEM_LISTING_ENABLED='false', PLAYIT_PUBLIC_ENDPOINT='', PLAYIT_HTTPS_HOST='')
        result = subprocess.run(['bash', str(script)], capture_output=True, text=True, env=env)
        cfg = server/'runtime/secrets.cfg'
        return result, cfg.read_text() if cfg.exists() else ''

    def test_secret_injection_rejected_in_renderer_and_entrypoint(self):
        for value in ['bad"value', 'bad\\value', 'bad\nsetr leak yes', 'bad\rvalue']:
            c.write_private(self.private/'resource_secrets.json', json.dumps({'ic_secret_smartphone_token':value}))
            with self.assertRaises(ValueError): c.render(self.private, self.schema)
        c.write_private(self.private/'resource_convars', 'setr leak=fixture\n')
        result, _ = self.entrypoint()
        self.assertNotEqual(result.returncode, 0)

    def test_unknown_json_field_and_invalid_webhook_rejected(self):
        for data in [{'unknown':'x'}, {'ic_secret_m_mdt_webhook':'https://example.invalid/token'}]:
            c.write_private(self.private/'resource_secrets.json', json.dumps(data))
            with self.assertRaises(ValueError): c.render(self.private, self.schema)

    def test_import_accepts_unquoted_cfg_license_and_does_not_import_hooks(self):
        source = self.root/'package'; (source/'config').mkdir(parents=True)
        (source/'config/keys.cfg').write_text('sv_licenseKey '+self.license+'\nset steam_webApiKey "'+'a'*32+'"\n')
        c.write_private(self.private/'cfx_license', '')
        c.import_package(self.private, source)
        self.assertEqual((self.private/'cfx_license').read_text(), self.license)
        self.assertEqual((self.private/'webhook_logs').read_text(), '')
        self.assertEqual(json.loads((self.private/'resource_secrets.json').read_text()), {})

    def test_import_does_not_replace_another_license(self):
        source = self.root/'package'; (source/'config').mkdir(parents=True)
        (source/'config/keys.cfg').write_text('sv_licenseKey cfxk_other_fixture\n')
        with self.assertRaises(ValueError): c.import_package(self.private, source)
        self.assertEqual((self.private/'cfx_license').read_text(), self.license)

    def archive(self, name, kind=None):
        archive = self.root/'code.tar'
        with tarfile.open(archive, 'w') as tar:
            member = tarfile.TarInfo(name); member.size = 1
            if kind: member.type = kind; member.linkname = '/tmp/escape'
            tar.addfile(member, io.BytesIO(b'x') if not kind else None)
        return archive

    def test_archive_rejects_paths_links_and_private_state(self):
        for name, kind in [('../escape', None), ('/escape', None), ('secrets/cfx_license', None),
                           ('.env.dev', None), ('db/default/CURRENT', None), ('.replxx_history', None),
                           ('config/keys.cfg', None), ('resources/link', tarfile.SYMTYPE)]:
            with self.assertRaises(ValueError): r.extract(self.archive(name, kind), self.root/'release')

    def test_manifest_detects_edit_addition_and_deletion(self):
        release = self.root/'release'; release.mkdir(); code = release/'server.cfg'; code.write_text('original')
        manifest = self.root/'manifest.json'; r.manifest(release, manifest)
        r.manifest(release, manifest, True)
        code.write_text('edited')
        with self.assertRaises(ValueError): r.manifest(release, manifest, True)
        code.write_text('original'); extra = release/'extra.json'; extra.write_text('{}')
        with self.assertRaises(ValueError): r.manifest(release, manifest, True)
        extra.unlink(); code.unlink()
        with self.assertRaises(ValueError): r.manifest(release, manifest, True)

    def test_manifest_excludes_only_designated_runtime_paths(self):
        release = self.root/'release'; release.mkdir(); (release/'server.cfg').write_text('original')
        (release/'runtime').mkdir(); (release/'runtime/secrets.cfg').write_text('fixture')
        (release/'.assets-state.json').write_text('{}')
        (release/'db').mkdir(); (release/'db/CURRENT').write_text('runtime KVP')
        (release/'.replxx_history').write_text('runtime console history')
        self.assertEqual(set(r.inventory(release)), {'server.cfg'})

    def simulated_deploy(self, fail=False, schema=False, schema_fail=False, persisted_desmanche=False, web_assets=False):
        """Exercise the installer in a temp root; Docker/privileged Linux commands are fakes."""
        base = self.root.resolve()/'deploy'; stage = self.root.resolve()/'stage'; stage.mkdir()
        store = self.root.resolve()/'store'; store.mkdir()
        source = self.root.resolve()/'code'; (source/'scripts').mkdir(parents=True); (source/'config').mkdir()
        for file in ('assets.py','configure-secrets.py','web-assets.py'): shutil.copyfile(ROOT/'scripts'/file,source/'scripts'/file)
        (source/'scripts/ic-admin-migrate.py').write_text('''import json,os,sys
with open(os.environ['FIXTURE_LOG'],'a') as out: out.write(json.dumps(['schema-migration']+sys.argv[1:])+'\\n')
sys.exit(int(os.environ.get('FIXTURE_SCHEMA_FAIL','0')))
''')
        (source/'config/resource-secrets.schema.json').write_text('{}')
        (source/'assets.lock.json').write_text(json.dumps({'format':1,'project':a.PROJECT,'packages':[]}))
        (source/'compose.yaml').write_text('services: {}\n')
        shutil.copyfile(ROOT/'compose.runtime.yaml',source/'compose.runtime.yaml')
        (source/'resources/[voip]/radio').mkdir(parents=True)
        (source/'resources/[voip]/radio/private_radios.json').write_text('{}')
        (source/'resources/[vrp]/vrp/cfg').mkdir(parents=True)
        (source/'resources/[vrp]/vrp/cfg/groups.json').write_text('{"groups":[]}')
        (source/'resources/[scripts]/m_desmanche').mkdir(parents=True)
        (source/'resources/[scripts]/m_desmanche/config.json').write_text('{"settings":{},"desmanches":[]}')
        (source/'server.cfg').write_text('fixture configuration\n')
        if web_assets:
            (source/'resources/inventory').mkdir()
            (source/'resources/inventory/main.js').write_text('const image="http://127.0.0.1/images/item.png";')
        archive = stage/'release.tar'
        with tarfile.open(archive,'w') as tar:
            for child in source.iterdir(): tar.add(child,arcname=child.name)
        shutil.copyfile(ROOT/'scripts/release.py',stage/'release.py')
        installer = (ROOT/'scripts/install-uriel-release.sh').read_text().replace('/opt/uriel/interior-city-tocado',str(base)).replace('/srv/diskaux/interior-city-assets',str(store))
        (stage/'install.sh').write_text(installer)
        old_sha, new_sha = 'a'*40, 'b'*40
        old = base/'releases'/old_sha; old.parent.mkdir(parents=True); shutil.copytree(source,old)
        (base/'state/manifests').mkdir(parents=True)
        radio_state=base/'state/resources/radio/private_radios.json'
        radio_state.parent.mkdir(parents=True)
        radio_state.write_text('{"fixture_channel":777}')
        desmanche_state=base/'state/resources/m_desmanche/config.json'
        if persisted_desmanche:
            desmanche_state.parent.mkdir(parents=True)
            desmanche_state.write_text('{"settings":{"edited":true},"desmanches":[{"name":"fixture"}]}')
        r.manifest(old,base/'state/manifests'/(old_sha+'.json'))
        (base/'current').symlink_to(old)
        c.initialize(base/'secrets'); c.write_private(base/'secrets/cfx_license',self.license)
        (base/'.env').write_text('COMPOSE_PROJECT_NAME=interior-city-tocado\nINTERIOR_CITY_RELEASE_PATH='+str(base)+'/current\nFIVEM_LISTING_ENABLED=false\nIC_ASSET_PROFILE=core\nASSET_STORE='+str(store)+'\n')
        if web_assets:
            media_source = self.root.resolve()/'media-source'
            for group in w.MEDIA: (media_source/group).mkdir(parents=True)
            (media_source/'images/item.png').write_bytes(b'fixture-image')
            w.import_media(media_source, base/'state/www')
            with (base/'.env').open('a') as out: out.write('IC_ASSETS_BASE_URL=https://city.example.invalid\n')
        binary = self.root/'bin'; binary.mkdir(); log = self.root/'docker.log'
        commands = {
            'id':'#!/bin/sh\necho 0\n', 'chown':'#!/bin/sh\nexit 0\n', 'flock':'#!/bin/sh\nexit 0\n',
            'stat': '#!/bin/sh\ncase "$3" in */secrets) echo root:700;; *) echo root:444;; esac\n',
            'docker': '#!'+os.sys.executable+'''\nimport json,os,sys
with open(os.environ['FIXTURE_LOG'],'a') as out: out.write(json.dumps(sys.argv[1:])+'\\n')
if os.environ.get('FIXTURE_DESMANCHE_MOUNT') and 'ps' in sys.argv:print('fixture-container')
if os.environ.get('FIXTURE_DESMANCHE_MOUNT') and 'inspect' in sys.argv:print(os.environ['FIXTURE_DESMANCHE_MOUNT'])
if 'stop' in sys.argv and not os.environ.get('FIXTURE_DESMANCHE_MOUNT'):
    from pathlib import Path
    Path(os.environ['FIXTURE_DESMANCHE_SOURCE']).write_text('{"settings":{"finalEdit":true},"desmanches":[]}')
if os.environ.get('FIXTURE_FAIL_UP')=='1' and 'up' in sys.argv and any('/'+('b'*40)+'/' in x for x in sys.argv):sys.exit(1)
''',
            'mv': '#!'+os.sys.executable+'''\nimport os,sys,shutil
args=[a for a in sys.argv[1:] if not a.startswith('-')]
if os.path.islink(args[1]): os.unlink(args[1])
shutil.move(*args)
''',
        }
        for name,script in commands.items(): p=binary/name; p.write_text(script); p.chmod(0o755)
        env=dict(os.environ,PATH=str(binary)+os.pathsep+os.environ['PATH'],FIXTURE_LOG=str(log),FIXTURE_FAIL_UP='1' if fail else '0',FIXTURE_SCHEMA_FAIL='1' if schema_fail else '0')
        env.update(FIXTURE_DESMANCHE_MOUNT=str(desmanche_state) if persisted_desmanche else '',FIXTURE_DESMANCHE_SOURCE=str(old/'resources/[scripts]/m_desmanche/config.json'))
        args=['bash',str(stage/'install.sh'),new_sha,str(archive)]
        if schema: args.append('--ic-admin-schema')
        result=subprocess.run(args,capture_output=True,text=True,env=env)
        self.assertEqual(json.loads(radio_state.read_text()), {'fixture_channel':777})
        expected={'settings':{'edited':True},'desmanches':[{'name':'fixture'}]} if persisted_desmanche else {'settings':{'finalEdit':True},'desmanches':[]}
        self.assertEqual(json.loads(desmanche_state.read_text()),expected)
        self.assertEqual(desmanche_state.stat().st_mode&0o777,0o600)
        events=[json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
        return result, (base/'current').resolve().name, events

    def test_installer_backs_up_before_switching_release(self):
        result,current,events=self.simulated_deploy()
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(current,'b'*40)
        backup=next(i for i,e in enumerate(events) if 'predeploy' in e)
        up=next(i for i,e in enumerate(events) if 'up' in e)
        self.assertLess(backup,up)
        self.assertFalse(any('down' in e for e in events))
        self.assertFalse(any('schema-migration' in e for e in events))

    def test_installer_renders_media_urls_before_sealing_the_release(self):
        result,current,events=self.simulated_deploy(web_assets=True)
        self.assertEqual(result.returncode,0,result.stderr)
        base=self.root.resolve()/'deploy'
        release=base/'releases'/current
        self.assertIn('https://city.example.invalid/images/item.png', (release/'resources/inventory/main.js').read_text())
        self.assertIn('127.0.0.1', (base/'releases'/('a'*40)/'resources/inventory/main.js').read_text())
        r.manifest(release,base/'state/manifests'/(current+'.json'),True)
        w.verify_media(base/'state/www')

    def test_installer_preserves_already_mounted_configuration_instead_of_release_defaults(self):
        result,current,events=self.simulated_deploy(persisted_desmanche=True)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(current,'b'*40)

    def test_explicit_admin_schema_runs_after_backup_before_start(self):
        result,current,events=self.simulated_deploy(schema=True)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(current,'b'*40)
        stop=next(i for i,e in enumerate(events) if 'stop' in e)
        backup=next(i for i,e in enumerate(events) if 'predeploy' in e)
        schema=next(i for i,e in enumerate(events) if 'schema-migration' in e)
        up=next(i for i,e in enumerate(events) if 'up' in e)
        self.assertLess(stop,backup);self.assertLess(backup,schema);self.assertLess(schema,up)
        self.assertIn('--writers-stopped',events[schema])

    def test_admin_schema_failure_restores_previous_code(self):
        result,current,events=self.simulated_deploy(schema=True,schema_fail=True)
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(current,'a'*40)
        self.assertIn('Database was not rolled back',result.stderr)
        self.assertEqual(sum('up' in e for e in events),1)

    def test_installer_restores_previous_code_when_start_fails(self):
        result,current,events=self.simulated_deploy(fail=True)
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(current,'a'*40)
        self.assertIn('Database was not rolled back',result.stderr)
        self.assertEqual(sum('up' in e for e in events),2)
        self.assertTrue(all(any(arg.endswith('/state/compose.runtime.yaml') for arg in e) for e in events if 'up' in e))

    def test_unicode_code_and_assets_use_same_linux_directory(self):
        archive = self.archive('resources/cafe\u0301/server.lua')
        release = self.root/'release'; r.extract(archive, release)
        expected = release/'resources/caf\u00e9'
        self.assertTrue((expected/'server.lua').is_file())
        self.assertEqual(a.target_path(release, 'resources/cafe\u0301/asset.ydr').parent, expected.resolve())

    def test_unicode_collision_in_catalogue_is_rejected(self):
        files = [{'path':name, 'size':1, 'sha256':'a'*64} for name in
                 ('resources/cafe\u0301/model.ydr','resources/caf\u00e9/model.ydr')]
        identifier = a.digest(a.canonical(files))
        lock = {'format':1,'project':a.PROJECT,'packages':[{'id':identifier,'profile':'core','files':files,
                'archive':{'object':a.PROJECT+'/objects/'+identifier+'.tar.gz'}}]}
        with self.assertRaises(ValueError): a.validate_lock(lock)

    @unittest.skipUnless(shutil.which('lua'), 'Lua interpreter not installed')
    def test_shared_config_never_reads_private_convar_on_client(self):
        script = ROOT/'resources/[scripts]/m_orgs_v2/config.lua'
        harness = '''
IsDuplicityVersion = function() return false end
GetConvar = function() error("client attempted private convar access") end
dofile(arg[1])
assert(Config.weebhooks.Withdraw == "")
assert(Config.weebhooks.Deposit == "")
'''
        lua = self.root/'check.lua'; lua.write_text(harness)
        result = subprocess.run(['lua',str(lua),str(script)], capture_output=True, text=True)
        self.assertEqual(result.returncode,0,result.stderr)

    @unittest.skipUnless(shutil.which('node'), 'Node interpreter not installed')
    def test_smartphone_private_values_are_not_serialized(self):
        text = (ROOT/'resources/[smartphone]/smartphone/server.js').read_text()
        snippet = text.split('const p9 = require(\'./config.json\');',1)[1].split('function pa()',1)[0]
        harness = '''const p9 = {token:'', webhookURL:'', publicField:'kept'};
const GetConvar = () => 'private-fixture';
'''+snippet+'''
if (p9.token !== 'private-fixture') process.exit(1);
const out = JSON.stringify(p9);
if (out.includes('private-fixture') || !out.includes('kept')) process.exit(2);
'''
        result = subprocess.run(['node','-e',harness],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr)

    @unittest.skipUnless(shutil.which('node'), 'Node interpreter not installed')
    def test_oxmysql_bundle_has_valid_javascript_syntax(self):
        result = subprocess.run(['node','--check',str(ROOT/'resources/[system]/oxmysql/dist/build.js')],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr)

    @unittest.skipUnless(shutil.which('lua'), 'Lua interpreter not installed')
    def test_unconfigured_webhooks_do_not_make_http_requests(self):
        text = (ROOT/'resources/[vrp]/vrp/server-side/snnipets.lua').read_text()
        function = re.search(r'function SendWebhookMessage\(.*?\nend',text,re.S)[0]
        harness = '''local calls=0
PerformHttpRequest=function() calls=calls+1 end
json={encode=function() return "{}" end}
'''+function+'''
SendWebhookMessage(nil,"event")
SendWebhookMessage("","event")
SendWebhookMessage("none","event")
assert(calls==0)
SendWebhookMessage("https://example.invalid/test","event")
assert(calls==1)
'''
        script = self.root/'webhook.lua'; script.write_text(harness)
        result = subprocess.run(['lua',str(script)],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr)


if __name__ == '__main__': unittest.main()
