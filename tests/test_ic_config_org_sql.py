"""Opt-in real MariaDB tests; disposable container, no network/ports/volumes.

IC_CONFIG_SQL_TEST=1 python3 -m unittest discover -s tests -p test_ic_config_org_sql.py -v
"""
import json
import importlib.util
import os
from pathlib import Path
import secrets
import subprocess
import tempfile
import time
import unittest

ROOT=Path(__file__).resolve().parents[1]
TABLES=['mirtin_orgs_goals','mirtin_orgs_player_infos','mirtin_orgs_chat','sjr_logs','mirtin_organization_members','mirtin_orgs_info']

def literal(value):
    if value is None:return 'NULL'
    if isinstance(value,(int,float)):return str(value)
    return "CONVERT(X'"+str(value).encode().hex()+"' USING utf8mb4)"

def bind(query):
    pieces=query['query'].split('?')
    values=query.get('values',[])
    if len(pieces)!=len(values)+1:raise AssertionError('Fixture parameter mismatch')
    return ''.join(piece+(literal(values[index]) if index<len(values) else '') for index,piece in enumerate(pieces))+';'

@unittest.skipUnless(os.environ.get('IC_CONFIG_SQL_TEST')=='1','Opt-in disposable MariaDB test')
class ICConfigOrgSQLTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.name='ic-config-org-test-'+secrets.token_hex(5)
        cls.private=tempfile.TemporaryDirectory(prefix='ic-config-org-')
        env=Path(cls.private.name)/'db.env'
        env.write_text('MARIADB_ROOT_PASSWORD='+secrets.token_hex(24)+'\nMARIADB_DATABASE=vrp\n');env.chmod(0o600)
        result=subprocess.run(['docker','run','-d','--rm','--network','none','--name',cls.name,'--env-file',str(env),'mariadb:10.11.19'],capture_output=True,text=True)
        if result.returncode:cls.private.cleanup();raise RuntimeError('Disposable MariaDB startup failed; private diagnostics omitted')
        cls.addClassCleanup(cls.cleanup)
        for _ in range(120):
            if cls.command('SELECT 1;',check=False).returncode==0:break
            time.sleep(.5)
        else:raise RuntimeError('Disposable database readiness timeout')
        emitted=subprocess.run(['lua',str(ROOT/'tests/ic_config_organizations.lua'),str(ROOT),'emit'],capture_output=True,text=True,check=True)
        cls.transactions=json.loads(emitted.stdout)

    @classmethod
    def cleanup(cls):
        subprocess.run(['docker','rm','-f',cls.name],capture_output=True)
        cls.private.cleanup()

    @classmethod
    def command(cls,sql,check=True):
        result=subprocess.run(['docker','exec','-i',cls.name,'sh','-c','MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb -uroot --batch --raw --skip-column-names --default-character-set=utf8mb4 vrp'],input=sql,capture_output=True,text=True)
        if check and result.returncode:raise AssertionError('Disposable SQL verification failed; private diagnostics omitted')
        return result

    def setUp(self):
        self.db='fixture_'+secrets.token_hex(5)
        self.command('CREATE DATABASE '+self.db+';USE '+self.db+';'+(ROOT/'database/schema.sql').read_text()+(ROOT/'database/ic_config/001_organizations.sql').read_text())
        raw=next(query['values'][2] for query in self.transactions[1] if 'BINARY dvalue=BINARY ?' in query['query'])
        self.sql("INSERT INTO vrp_users(id) VALUES(71001);INSERT INTO vrp_user_data(user_id,dkey,dvalue) VALUES(71001,'vRP:datatable',"+literal(raw)+");"
            "INSERT INTO mirtin_orgs_goals(user_id,organization,item,amount,day,month) VALUES(71001,'Test','water',1,1,1);"
            "INSERT INTO mirtin_orgs_player_infos(user_id,organization) VALUES(71001,'Test');"
            "INSERT INTO mirtin_orgs_chat(organization,user_id,message,author) VALUES('Test',71001,'fixture','fixture');"
            "INSERT INTO sjr_logs(organization,user_id) VALUES('Test',71001);"
            "INSERT INTO mirtin_organization_members(user_id,group_type,item,amount,day,month) VALUES(71001,'Test','water',1,'1','1');"
            "INSERT INTO mirtin_orgs_info(organization) VALUES('Test'),('Other');")

    def sql(self,value,check=True):return self.command('USE '+self.db+';'+value,check)
    def transaction(self,index,extra=''):
        return self.sql('START TRANSACTION;'+''.join(bind(query) for query in self.transactions[index])+extra+'COMMIT;',check=False)

    def test_schema_repeatable_and_all_guard_triggers_exist(self):
        self.sql((ROOT/'database/ic_config/001_organizations.sql').read_text())
        self.assertEqual(self.sql('SELECT MAX(version) FROM ic_config_schema;').stdout.strip(),'1')
        self.assertEqual(self.sql("SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE() AND TRIGGER_NAME LIKE 'ic_config_%';").stdout.strip(),'14')
        spec=importlib.util.spec_from_file_location('ic_config_migrate_sql',ROOT/'scripts/ic-config-migrate.py')
        migration=importlib.util.module_from_spec(spec);spec.loader.exec_module(migration)
        parent=self
        class DB:
            def query(self,sql):return parent.sql(sql).stdout.strip()
        self.assertEqual(migration.verify_schema(DB())['triggersVerified'],14)
        self.assertEqual(migration.apply_schema(DB())['schemaVersion'],1)

    def test_actual_lua_transactions_remove_only_target_and_clean_memberships(self):
        self.assertEqual(self.transaction(0).returncode,0)
        self.assertEqual(self.transaction(1).returncode,0)
        for table in TABLES:
            column='group_type' if table=='mirtin_organization_members' else 'organization'
            self.assertEqual(self.sql('SELECT COUNT(*) FROM '+table+' WHERE '+column+"='Test';").stdout.strip(),'0')
        self.assertEqual(self.sql("SELECT phase FROM ic_config_org_deletions WHERE org_name='Test';").stdout.strip(),'sql_committed')
        self.assertEqual(self.sql("SELECT COUNT(*) FROM mirtin_orgs_info WHERE organization='Other';").stdout.strip(),'1')
        value=json.loads(self.sql("SELECT dvalue FROM vrp_user_data WHERE user_id=71001 AND dkey='vRP:datatable';").stdout.strip())
        self.assertNotIn('MembroTest',value['groups']);self.assertNotIn('MembroTest',value['vip_group_expirations'])
        self.assertTrue(value['groups']['user']);self.assertEqual(value['other'],'preserve')

    def test_failure_rolls_back_all_six_tables_and_user_changes(self):
        self.assertEqual(self.transaction(0).returncode,0)
        self.assertNotEqual(self.transaction(1,'INSERT INTO ic_config_schema(version) VALUES(1);').returncode,0)
        for table in TABLES:
            column='group_type' if table=='mirtin_organization_members' else 'organization'
            self.assertEqual(self.sql('SELECT COUNT(*) FROM '+table+' WHERE '+column+"='Test';").stdout.strip(),'1')
        self.assertEqual(self.sql("SELECT phase FROM ic_config_org_deletions WHERE org_name='Test';").stdout.strip(),'prepared')
        value=json.loads(self.sql("SELECT dvalue FROM vrp_user_data WHERE user_id=71001 AND dkey='vRP:datatable';").stdout.strip())
        self.assertTrue(value['groups']['MembroTest'])
        self.assertEqual(self.transaction(1).returncode,0)

    def test_late_org_writes_blocked_and_stale_userdata_cannot_restore_membership(self):
        self.assertEqual(self.transaction(0).returncode,0)
        self.assertNotEqual(self.sql("INSERT INTO sjr_logs(organization,user_id) VALUES('Test',71001);",check=False).returncode,0)
        self.assertNotEqual(self.sql("UPDATE mirtin_orgs_info SET organization='Test' WHERE organization='Other';",check=False).returncode,0)
        self.sql("INSERT INTO sjr_logs(organization,user_id) VALUES('Other',71001);")
        stale=json.dumps({'groups':{'MembroTest':True,'user':True},'vip_group_expirations':{'MembroTest':999},'money':42})
        self.sql("REPLACE INTO vrp_user_data(user_id,dkey,dvalue) VALUES(71001,'vRP:datatable',"+literal(stale)+');')
        value=json.loads(self.sql("SELECT dvalue FROM vrp_user_data WHERE user_id=71001 AND dkey='vRP:datatable';").stdout.strip())
        self.assertNotIn('MembroTest',value['groups']);self.assertEqual(value['money'],42)

    def test_explicit_recreation_archives_guards_and_allows_new_organization(self):
        self.assertEqual(self.transaction(0).returncode,0);self.assertEqual(self.transaction(1).returncode,0)
        self.sql("START TRANSACTION;UPDATE ic_config_org_deletions SET phase='recreated' WHERE org_name='Test';DELETE FROM ic_config_deleted_groups;COMMIT;")
        self.sql("INSERT INTO mirtin_orgs_info(organization) VALUES('Test');")
        self.assertEqual(self.sql("SELECT COUNT(*) FROM mirtin_orgs_info WHERE organization='Test';").stdout.strip(),'1')
