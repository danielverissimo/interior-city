"""Opt-in real MariaDB verification in a disposable, network-isolated container.

IC_ADMIN_SQL_TEST=1 python3 -m unittest discover -s tests -p test_ic_admin_sql.py -v
No host database, volumes, published port or real credential is used.
"""
import importlib.util
import os
from pathlib import Path
import secrets
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
        cls.command((ROOT/'database/ic_admin/001_initial.sql').read_text())

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
        self.assertEqual(self.command("SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='vrp';").stdout.strip(),'210')
        self.assertEqual(self.command('SELECT MAX(version) FROM ic_admin_schema;').stdout.strip(),'1')
        self.assertEqual(self.command("SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='vrp' AND TABLE_NAME='mirtin_bans' AND COLUMN_NAME IN ('owner','staff');").stdout.strip(),'2')

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
