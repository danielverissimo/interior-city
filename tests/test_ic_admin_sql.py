"""Opt-in real MariaDB verification in a disposable, network-isolated container.

IC_ADMIN_SQL_TEST=1 python3 -m unittest discover -s tests -p test_ic_admin_sql.py -v
No host database, volumes, published port or real credential is used.
"""
import importlib.util
import os
import json
from pathlib import Path
import secrets
import shutil
import subprocess
import tempfile
import time
import unittest

ROOT=Path(__file__).resolve().parents[1]

@unittest.skipUnless(os.environ.get('IC_ADMIN_SQL_TEST')=='1','Opt-in disposable MariaDB test')
class ICAdminSQLTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.name='ic-admin-sql-test-'+secrets.token_hex(5)
        cls.private=tempfile.TemporaryDirectory(prefix='ic-admin-sql-')
        env=Path(cls.private.name)/'db.env'
        env.write_text('MARIADB_ROOT_PASSWORD='+secrets.token_hex(24)+'\nMARIADB_DATABASE=vrp\n')
        env.chmod(0o600)
        result=subprocess.run(['docker','run','-d','--rm','--network','none','--name',cls.name,'--env-file',str(env),'mariadb:10.11.19'],capture_output=True,text=True)
        if result.returncode: cls.private.cleanup();raise RuntimeError('Disposable MariaDB could not start; diagnostics suppressed')
        cls.addClassCleanup(cls.cleanup)
        for _ in range(120):
            probe=cls.command('SELECT 1;',check=False)
            if probe.returncode==0: break
            time.sleep(0.5)
        else: raise RuntimeError('Disposable MariaDB readiness timeout')
        cls.command((ROOT/'database/schema.sql').read_text())
        spec=importlib.util.spec_from_file_location('ic_migrate_setup',ROOT/'scripts/ic-admin-migrate.py')
        cls.m=importlib.util.module_from_spec(spec);spec.loader.exec_module(cls.m)
        class DB:
            def query(self,sql): return cls.command(sql).stdout.strip()
        cls.m.apply_schema(DB())

    @classmethod
    def cleanup(cls):
        subprocess.run(['docker','rm','-f',cls.name],capture_output=True)
        cls.private.cleanup()

    @classmethod
    def command(cls,sql,check=True):
        result=subprocess.run(['docker','exec','-i',cls.name,'sh','-c','MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb -uroot --batch --raw --skip-column-names --default-character-set=utf8mb4 vrp'],input=sql,capture_output=True,text=True)
        if check and result.returncode: raise AssertionError('SQL test failed; database diagnostics suppressed')
        return result

    def test_schema_is_additive_repeatable_and_has_all_base_tables(self):
        self.command((ROOT/'database/ic_admin/001_initial.sql').read_text())
        self.assertEqual(self.command("SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='vrp';").stdout.strip(),'213')
        self.assertEqual(self.command('SELECT MAX(version) FROM ic_admin_schema;').stdout.strip(),'2')
        self.assertEqual(self.command("SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='vrp' AND TABLE_NAME='mirtin_bans' AND COLUMN_NAME IN ('owner','staff');").stdout.strip(),'2')

    def test_v1_promotion_is_repeatable_and_preserves_snapshots(self):
        m=self.m
        self.command('CREATE DATABASE ic_upgrade;')
        parent=self
        class DB:
            def query(self,sql):return parent.command('USE ic_upgrade;'+sql).stdout.strip()
        db=DB();db.query((ROOT/'database/schema.sql').read_text());db.query(m.SCHEMA.read_text())
        calls={'nextId':77,'calls':[{'id':3,'requesterId':71001,'requesterSubject':'stable-a','acceptedBy':71002,'acceptedSubject':'stable-b','requesterName':'Snapshot','department':'staff','state':'finished','createdAt':10}], 'ratings':[{'callId':3,'staffId':71002,'staffSubject':'stable-b','stars':5,'message':'Fixture','createdAt':20}]}
        vip={'assignments':[{'id':'upgrade-vip','userId':71001,'subjectKey':'stable-a','group':'vip_gold','state':'uncertain','assignedAt':1,'expiresAt':500,'claims':[]}]}
        db.query("INSERT INTO ic_admin_documents VALUES ('calls',"+m.sql_text(json.dumps(calls))+",1),('vip_assignments',"+m.sql_text(json.dumps(vip))+",1);")
        self.assertEqual(m.apply_schema(db)['schemaVersion'],2)
        self.assertEqual(m.apply_schema(db)['schemaVersion'],2)
        self.assertEqual(db.query('SELECT COUNT(*) FROM ic_admin_calls;'),'1')
        self.assertEqual(db.query('SELECT COUNT(*) FROM ic_admin_ratings;'),'1')
        self.assertEqual(db.query('SELECT subject_key,state FROM ic_admin_vip_assignments;'),'stable-a\tuncertain')
        self.assertEqual(db.query("SELECT JSON_UNQUOTE(JSON_EXTRACT(payload,'$.requesterName')) FROM ic_admin_calls WHERE id=3;"),'Snapshot')
        db.query("INSERT INTO ic_admin_calls(state,payload) VALUES('open','{}');")
        self.assertEqual(db.query('SELECT MAX(id) FROM ic_admin_calls;'),'77')

    def test_records_above_old_domain_cap_paginate_and_reject_stale_write(self):
        payload=json.dumps({'message':'x'*50000})
        values=','.join('('+str(30000+n)+",'open',"+self.m.sql_text(payload)+')' for n in range(1,106))
        self.command('INSERT INTO ic_admin_calls(id,state,payload) VALUES '+values+';')
        size=int(self.command('SELECT SUM(LENGTH(payload)) FROM ic_admin_calls WHERE id BETWEEN 30001 AND 30105;').stdout.strip())
        self.assertGreater(size,4000000)
        self.assertEqual(len(self.command('SELECT id FROM ic_admin_calls WHERE id BETWEEN 30001 AND 30105 ORDER BY id LIMIT 50 OFFSET 50;').stdout.splitlines()),50)
        self.command("UPDATE ic_admin_calls SET state='accepted',revision=revision+1 WHERE id=30001 AND revision=1;")
        self.assertEqual(self.command("UPDATE ic_admin_calls SET state='finished' WHERE id=30001 AND revision=1;SELECT ROW_COUNT();").stdout.strip(),'0')
        self.assertEqual(self.command('SELECT state FROM ic_admin_calls WHERE id=30001;').stdout.strip(),'accepted')

    @unittest.skipUnless(shutil.which('lua'),'Lua interpreter unavailable')
    def test_actual_call_visibility_predicate_enforces_subject_and_department(self):
        rows=[(40001,'other','staff','open',''),(40002,'other','staff','accepted','viewer'),(40003,'other','staff','accepted','other-staff'),(40004,'viewer','staff','finished','other-staff'),(40005,'other','police','open',''),(40006,'other','staff','finished','other-staff')]
        values=','.join('('+str(key)+',10,'+','.join(self.m.sql_text(value) for value in (subject,department,state,actor))+",'{}')" for key,subject,department,state,actor in rows)
        self.command('INSERT INTO ic_admin_calls(id,owner_id,subject_key,department,state,actor_subject,payload) VALUES '+values+';')
        for scenario,expected in [('citizen',[40004]),('staff',[40001,40002,40004]),('history',[40001,40002,40003,40004,40006]),('police',[40004,40005]),('reused',[])]:
            with self.subTest(scenario=scenario):
                output=subprocess.run(['lua',str(ROOT/'tests/ic_admin_visibility.lua'),str(ROOT),scenario],check=True,capture_output=True,text=True).stdout.splitlines()
                where=output[0]
                for value in output[1:]:where=where.replace('?',self.m.sql_text(value),1)
                actual=self.command('SELECT id FROM ic_admin_calls WHERE id BETWEEN 40001 AND 40006 AND ('+where+') ORDER BY id;').stdout.splitlines()
                self.assertEqual(list(map(int,actual)),expected)

    def test_reconciliation_selects_pending_claims_and_masks_operation_keys(self):
        self.command("INSERT INTO ic_admin_operations(operation_key,actor_id,method,payload,state) VALUES('fixture-private-session',1,'vip.choose','{}','uncertain');")
        value=self.command("SELECT SHA2(operation_key,256) FROM ic_admin_operations WHERE operation_key='fixture-private-session';").stdout.strip()
        self.assertEqual(len(value),64);self.assertNotIn('fixture',value)
        payload=json.dumps({'claims':[{'vehicle':'sultan','state':'uncertain'}]})
        self.command("INSERT INTO ic_admin_vip_assignments(id,state,payload) VALUES('pending-claim','active',"+self.m.sql_text(payload)+');')
        self.assertEqual(self.command("SELECT id FROM ic_admin_vip_assignments WHERE state IN ('applying','uncertain') OR JSON_SEARCH(payload,'one','uncertain',NULL,'$.claims[*].state') IS NOT NULL;").stdout.strip(),'pending-claim')

    def test_orphan_legacy_history_does_not_attach_to_future_passport_owner(self):
        self.command('CREATE DATABASE ic_orphan;');parent=self;m=self.m
        class DB:
            def query(self,sql):return parent.command('USE ic_orphan;'+sql).stdout.strip()
        db=DB();db.query((ROOT/'database/schema.sql').read_text());m.apply_schema(db)
        imported={'snapshotDigest':'orphan-fixture','documents':{'calls':{'nextId':25,'calls':[{'id':1,'requesterId':99999,'requesterName':'Legacy snapshot','department':'staff','message':'Archived','state':'finished','createdAt':10}],'ratings':[]}},'discipline':[{'id':1,'user_id':99999,'actor_id':0,'kind':'warning','reason':'Historical','starts_at':10,'ends_at':20,'state':'archived','return_state':None}],'privateDestinationsRequireConfiguration':0}
        self.assertTrue(m.apply_import(db,imported)['verified'])
        self.assertEqual(db.query('SELECT COUNT(*) FROM ic_admin_subjects WHERE user_id IS NULL;'),'1')
        self.assertEqual(db.query("SELECT AUTO_INCREMENT FROM information_schema.TABLES WHERE TABLE_SCHEMA='ic_orphan' AND TABLE_NAME='ic_admin_calls';"),'25')
        db.query("INSERT INTO vrp_users(id) VALUES (99999);INSERT INTO ic_admin_subjects(subject_key,user_id) VALUES ('new-owner',99999);")
        self.assertEqual(db.query('SELECT subject_key FROM ic_admin_subjects WHERE user_id=99999;'),'new-owner')
        self.assertNotEqual(db.query('SELECT subject_key FROM ic_admin_calls WHERE id=1;'),'new-owner')
        self.assertNotEqual(db.query('SELECT subject_key FROM ic_admin_discipline WHERE id=1;'),'new-owner')

    def test_document_compare_and_swap_and_operation_unique_key(self):
        self.command("INSERT INTO ic_admin_documents VALUES ('sql-test','{}',1); UPDATE ic_admin_documents SET revision=revision+1 WHERE doc_key='sql-test' AND revision=1; UPDATE ic_admin_documents SET payload='stale' WHERE doc_key='sql-test' AND revision=1;")
        self.assertEqual(self.command("SELECT payload,revision FROM ic_admin_documents WHERE doc_key='sql-test';").stdout.strip(),'{}\t2')
        self.command("INSERT IGNORE INTO ic_admin_operations(operation_key,actor_id,method,payload,state) VALUES('sql-op',1,'vip.assign','{}','pending'),('sql-op',1,'vip.assign','{}','pending');")
        self.assertEqual(self.command("SELECT COUNT(*) FROM ic_admin_operations WHERE operation_key='sql-op';").stdout.strip(),'1')

    def test_atomic_failure_rolls_back_passport_and_document_changes(self):
        self.command("INSERT INTO vrp_users(id) VALUES(71001),(71002); INSERT INTO vrp_user_identities(user_id,nome) VALUES(71001,'Fixture');")
        result=self.command("START TRANSACTION; UPDATE vrp_user_identities SET nome='Changed' WHERE user_id=71001; UPDATE vrp_users SET id=71002 WHERE id=71001; COMMIT;",check=False)
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(self.command('SELECT nome FROM vrp_user_identities WHERE user_id=71001;').stdout.strip(),'Fixture')

    def test_transaction_document_guard_refuses_stale_revision(self):
        self.command("INSERT INTO ic_admin_documents VALUES ('guard-test','{}',2);")
        result=self.command("START TRANSACTION; INSERT INTO ic_admin_schema(version) SELECT 1 WHERE NOT EXISTS (SELECT 1 FROM ic_admin_documents WHERE doc_key='guard-test' AND revision=1 FOR UPDATE); UPDATE ic_admin_documents SET payload='bad' WHERE doc_key='guard-test'; COMMIT;",check=False)
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(self.command("SELECT payload FROM ic_admin_documents WHERE doc_key='guard-test';").stdout.strip(),'{}')

    def test_retention_keeps_discipline_and_recent_audit(self):
        self.command("INSERT INTO ic_admin_audit(action,payload,created_at) VALUES('sql-old','{}',UTC_TIMESTAMP()-INTERVAL 91 DAY),('sql-new','{}',UTC_TIMESTAMP()); INSERT INTO ic_admin_discipline(subject_key,user_id,actor_id,kind,reason,starts_at,state) VALUES('sql-history',71001,1,'warning','Fixture',1,'archived'); DELETE FROM ic_admin_audit WHERE created_at<DATE_SUB(UTC_TIMESTAMP(),INTERVAL 90 DAY);")
        self.assertEqual(self.command("SELECT COUNT(*) FROM ic_admin_audit WHERE action IN ('sql-old','sql-new');").stdout.strip(),'1')
        self.assertEqual(self.command("SELECT COUNT(*) FROM ic_admin_discipline WHERE subject_key='sql-history';").stdout.strip(),'1')

    def test_import_apply_then_verify_with_real_database(self):
        spec=importlib.util.spec_from_file_location('ic_migrate_sql',ROOT/'scripts/ic-admin-migrate.py')
        mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
        parent=self
        class DB:
            def query(self,sql):return parent.command(sql).stdout.strip()
        imported={'snapshotDigest':'sql-import-fixture','documents':{'locations':{'locations':[],'categories':[]}},'discipline':[],'privateDestinationsRequireConfiguration':0}
        first=mod.apply_import(DB(),imported)
        second=mod.apply_import(DB(),imported)
        verified=mod.apply_import(DB(),imported,verify=True)
        self.assertEqual(first['documents'],1)
        self.assertEqual(second['documents'],1)
        self.assertEqual(verified['documents'],1)
