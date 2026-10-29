import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tarfile
import tempfile
import unittest
from unittest.mock import patch

spec=importlib.util.spec_from_file_location('assets',Path(__file__).parents[1]/'scripts/assets.py')
a=importlib.util.module_from_spec(spec);spec.loader.exec_module(a)


class AssetTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name);self.source=self.root/'source';self.code=self.root/'code';self.store=self.root/'store'
        self.code.mkdir();(self.source/'resources/[scripts]/example/stream').mkdir(parents=True)
        (self.source/'resources/[scripts]/example/fxmanifest.lua').write_text("fx_version 'cerulean'\n")
        (self.source/'resources/[scripts]/example/server.lua').write_text('local running=true\n')
        (self.source/'resources/[scripts]/example/stream/model.ydr').write_bytes(b'fake-model-data')
        (self.source/'config').mkdir();(self.source/'database').mkdir()
        (self.source/'config/keys.cfg').write_text('never import this private file')
        (self.source/'database/databasedelux.sql').write_text("CREATE TABLE example(id INT, note TEXT DEFAULT 'a;b'); INSERT INTO example VALUES(1,'private'); DROP DATABASE example;")

    def prepare(self):
        with contextlib.redirect_stdout(io.StringIO()):a.prepare(self.source,self.code)
        return json.loads((self.code/'assets.lock.json').read_text())

    def publish(self):
        with contextlib.redirect_stdout(io.StringIO()):a.publish(self.code/'assets.lock.json',self.source,str(self.store))
        return json.loads((self.code/'assets.lock.json').read_text())

    def test_separation_and_original_preserved(self):
        before=(self.source/'database/databasedelux.sql').read_bytes();lock=self.prepare()
        self.assertFalse((self.code/'config/keys.cfg').exists())
        self.assertTrue((self.code/'resources/[scripts]/example/server.lua').exists())
        self.assertFalse((self.code/'resources/[scripts]/example/stream/model.ydr').exists())
        sql=(self.code/'database/schema.sql').read_text()
        self.assertIn('CREATE TABLE',sql);self.assertNotIn('private',sql);self.assertNotIn('DROP DATABASE',sql)
        self.assertEqual(before,(self.source/'database/databasedelux.sql').read_bytes());self.assertEqual(lock['stats']['asset_files'],1)

    def test_secrets_redacted_without_logging_values(self):
        cfx='cfx'+'k_NOT_A_REAL_CREDENTIAL';url='https://discord.com/api/'+'webhooks/123456/example-not-real'
        text='sv_licenseKey "'+cfx+'"\nset mysql_connection_string "mysql:'+'//user:fake@db/base"\nexec config/keys.cfg\nadd_principal identifier.steam:example group.admin\n'
        clean,changes=a.sanitize(text,'config/config.cfg')
        self.assertNotIn(cfx,clean);self.assertNotIn('mysql:',clean);self.assertNotIn('identifier.steam',clean)
        clean,changes=a.sanitize('local hook="'+url+'"\npassword="not-a-real-password"','server.lua')
        self.assertNotIn(url,clean);self.assertNotIn('not-a-real-password',clean);self.assertTrue(changes)

    def test_sanitization_preserves_connection_parser_string_literals(self):
        code = 'const options = input.replace(/(?:pwd|pass)=/gi, "password=").replace(/(?:db)=/gi, "database=");'
        clean, changes = a.sanitize(code, 'resources/oxmysql/dist/build.js')
        self.assertEqual(clean, code)
        self.assertFalse(changes)

    def test_sql_split_keeps_quoted_semicolon(self):
        sql="-- comment\nCREATE TABLE x(v TEXT DEFAULT 'a;b');\nINSERT INTO x VALUES('secret');"
        clean=a.schema_only(sql);self.assertIn("'a;b'",clean);self.assertNotIn("'secret'",clean)

    def test_schema_import_scopes_foreign_key_override_to_its_session(self):
        clean=a.schema_only('CREATE TABLE child(id INT); SET GLOBAL FOREIGN_KEY_CHECKS=0;')
        self.assertIn('SET @IC_PREVIOUS_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS;',clean)
        self.assertLess(clean.index('SET FOREIGN_KEY_CHECKS = 0;'),clean.index('CREATE TABLE'))
        self.assertTrue(clean.rstrip().endswith('SET FOREIGN_KEY_CHECKS = @IC_PREVIOUS_FOREIGN_KEY_CHECKS;'))
        self.assertNotIn('SET GLOBAL',clean)

    def test_sql_comment_markers_inside_literals_are_preserved(self):
        sql="/* dump */\nCREATE TABLE x(v TEXT DEFAULT '/* keep */');"
        self.assertIn("'/* keep */'",a.schema_only(sql))

    def test_roster_tampering_rejected(self):
        lock=self.prepare();lock['packages'][0]['files'][0]['size']+=1
        with self.assertRaises(ValueError):a.validate_lock(lock)

    def test_roundtrip_and_repeatable_archive(self):
        lock=self.prepare();package=lock['packages'][0];x=io.BytesIO();y=io.BytesIO()
        a.write_archive(package,self.source,x);a.write_archive(package,self.source,y);self.assertEqual(x.getvalue(),y.getvalue())
        self.publish()
        with contextlib.redirect_stdout(io.StringIO()):a.sync(self.code/'assets.lock.json',self.code,'core',str(self.store))
        self.assertEqual((self.code/'resources/[scripts]/example/stream/model.ydr').read_bytes(),b'fake-model-data')

    def test_changed_source_rejected_before_publication(self):
        self.prepare();(self.source/'resources/[scripts]/example/stream/model.ydr').write_bytes(b'FAKE-MODEL-DATA')
        with self.assertRaises(ValueError):self.publish()
        self.assertFalse(list(self.store.rglob('*.tar.gz')))

    def test_archive_extra_file_rejected(self):
        lock=self.prepare();path=self.root/'bad.tar.gz'
        with tarfile.open(path,'w:gz') as tar:
            m=tarfile.TarInfo('../escape');m.size=1;tar.addfile(m,io.BytesIO(b'x'))
        with self.assertRaises(ValueError):a.verify_archive(path,lock['packages'][0],self.code)
        self.assertFalse((self.root/'escape').exists())

    def test_modified_installed_asset_is_not_overwritten(self):
        self.prepare();self.publish();out=self.code/'resources/[scripts]/example/stream/model.ydr';out.parent.mkdir(parents=True);out.write_bytes(b'my edit')
        with self.assertRaises(ValueError):a.sync(self.code/'assets.lock.json',self.code,'core',str(self.store))
        self.assertEqual(out.read_bytes(),b'my edit')

    def test_destination_symlink_is_rejected(self):
        other=self.root/'outside';other.mkdir();(self.code/'resources').symlink_to(other,target_is_directory=True)
        with self.assertRaises(ValueError):a.target_path(self.code,'resources/file.ydr')

    def test_bad_remote_store_rejected(self):
        for store in ['-oProxyCommand=bad@host:/tmp','user@host:relative','user@host:/tmp/../data']:
            with self.assertRaises(ValueError):a.parse_store(store)

    def test_corrupt_download_is_rejected_before_install(self):
        self.prepare();lock=self.publish();obj=self.store/lock['packages'][0]['archive']['object']
        with obj.open('ab') as stream:stream.write(b'corruption')
        with self.assertRaises(ValueError):a.sync(self.code/'assets.lock.json',self.code,'core',str(self.store))
        self.assertFalse((self.code/'resources/[scripts]/example/stream/model.ydr').exists())

    def test_space_preflight_does_not_download(self):
        self.prepare();self.publish()
        with patch.object(a.shutil,'disk_usage',return_value=type('Space',(),{'free':0})()):
            with self.assertRaises(ValueError):a.sync(self.code/'assets.lock.json',self.code,'core',str(self.store))
        self.assertFalse((self.code/'.assets-cache').exists())

    def test_nested_import_destination_is_rejected(self):
        with self.assertRaises(ValueError):a.prepare(self.source,self.source/'nested')

    def test_incomplete_catalogue_cannot_be_sealed(self):
        self.prepare()
        with self.assertRaises(ValueError):a.seal_catalog(self.code/'assets.lock.json',str(self.store))

    def test_catalogue_is_preserved_in_private_store(self):
        self.prepare();self.publish();identifier=a.file_hash(self.code/'assets.lock.json')
        stored=self.store/a.PROJECT/'catalogs'/(identifier+'.json')
        self.assertEqual(stored.read_bytes(),(self.code/'assets.lock.json').read_bytes())
        with contextlib.redirect_stdout(io.StringIO()):self.assertEqual(a.seal_catalog(self.code/'assets.lock.json',str(self.store)),identifier)

    def test_rage_binary_with_ascii_bytes_and_model_source_are_assets(self):
        stream=self.source/'resources/[scripts]/example/stream'
        (stream/'_manifest.ymf').write_bytes(b'RAGE\x00\x01\x02')
        (stream/'car.yft.xml').write_text('<Fragment/>')
        lock=self.prepare();assets={f['path'] for p in lock['packages'] for f in p['files']}
        self.assertIn('resources/[scripts]/example/stream/_manifest.ymf',assets)
        self.assertIn('resources/[scripts]/example/stream/car.yft.xml',assets)
        self.assertFalse((self.code/'resources/[scripts]/example/stream/_manifest.ymf').exists())

    def test_failed_write_leaves_no_partial_asset(self):
        lock=self.prepare();self.publish();package=lock['packages'][0];obj=self.store/package['archive']['object']
        with patch.object(a.shutil,'copyfileobj',side_effect=OSError('simulated write failure')):
            with self.assertRaises(OSError):a.verify_archive(obj,package,self.code)
        self.assertFalse(list(self.code.rglob('.asset-part-*')))
        self.assertFalse((self.code/'resources/[scripts]/example/stream/model.ydr').exists())

    def test_hash_alias_installs_independent_media_and_refuses_modified_copy(self):
        lock=self.prepare();self.publish()
        source=lock['packages'][0]['files'][0]
        aliases=[{'sha256':source['sha256'],'size':source['size'],'destination':'resources/ic_admin/web/assets/map.png'}]
        config=self.code/'config/asset-aliases.json';config.parent.mkdir(exist_ok=True);config.write_text(json.dumps(aliases))
        with contextlib.redirect_stdout(io.StringIO()):a.sync(self.code/'assets.lock.json',self.code,'full',str(self.store))
        dest=self.code/aliases[0]['destination']
        self.assertEqual(a.file_hash(dest),source['sha256'])
        dest.write_bytes(b'modified')
        with self.assertRaises(ValueError):a.install_aliases(self.code/'assets.lock.json',lock,self.code,'full')

    def test_alias_requires_admitted_hash_and_rejects_code_destination(self):
        lock=self.prepare();source=lock['packages'][0]['files'][0]
        config=self.code/'config/asset-aliases.json';config.parent.mkdir(exist_ok=True)
        config.write_text(json.dumps([{'sha256':'0'*64,'size':1,'destination':'resources/ic_admin/map.png'}]))
        with self.assertRaises(ValueError):a.asset_aliases(self.code/'assets.lock.json',lock,'full')
        config.write_text(json.dumps([{'sha256':source['sha256'],'size':source['size'],'destination':'resources/ic_admin/server.lua'}]))
        with self.assertRaises(ValueError):a.asset_aliases(self.code/'assets.lock.json',lock,'full')


if __name__=='__main__':unittest.main()
