"""Opt-in real backup/restore rehearsal with isolated MariaDB containers."""
import gzip
import importlib.util
import os
from pathlib import Path
import secrets
import subprocess
import tempfile
import time
import unittest

ROOT=Path(__file__).resolve().parents[1]
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);value=importlib.util.module_from_spec(spec);spec.loader.exec_module(value);return value
c=module('cutover_sql_test',ROOT/'scripts/ic-config-cutover.py')
m=module('cutover_migration_test',ROOT/'scripts/ic-config-migrate.py')

@unittest.skipUnless(os.environ.get('IC_CONFIG_SQL_TEST')=='1','Opt-in disposable MariaDB backup rehearsal')
class CutoverSQLTests(unittest.TestCase):
    def test_restored_backup_accepts_repeated_schema_and_keeps_player_data(self):
        with tempfile.TemporaryDirectory(prefix='ic-config-rehearse-')as tmp:
            work=Path(tmp).resolve();env=work/'source.env';name='ic-config-source-'+secrets.token_hex(5)
            env.write_text('MARIADB_ROOT_PASSWORD='+secrets.token_hex(32)+'\nMARIADB_DATABASE=vrp\n');env.chmod(0o600)
            try:
                c.run(['docker','run','-d','--rm','--pull','never','--network','none','--name',name,'--env-file',str(env),'mariadb:10.11.19'])
                command=['docker','exec','-i',name,'sh','-c','MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb -uroot --batch --raw --skip-column-names --binary-mode --default-character-set=utf8mb4 vrp']
                class DB:
                    def query(self,sql):return c.run(command,sql)
                live=DB()
                for _ in range(120):
                    try:live.query('SELECT 1;');break
                    except c.CutoverError:time.sleep(.5)
                else:raise AssertionError('Fixture database not ready')
                live.query((ROOT/'database/schema.sql').read_text())
                live.query("INSERT INTO vrp_users(id) VALUES(71001);INSERT INTO vrp_user_data(user_id,dkey,dvalue) VALUES(71001,'vRP:datatable','{\"groups\":{\"LiderFixture\":true},\"fixtureBalance\":321}');")
                original=live.query("SELECT HEX(dvalue) FROM vrp_user_data WHERE user_id=71001 AND dkey='vRP:datatable';")
                dump=c.run(['docker','exec',name,'sh','-c','MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb-dump -uroot --single-transaction --quick --no-tablespaces --databases vrp'])
                backup=work/'vrp.sql.gz'
                with gzip.open(backup,'wt')as stream:stream.write(dump)
                backup.chmod(0o600)
                outer=self
                class VerifiedMigration:
                    @staticmethod
                    def apply_schema(db):
                        outer.assertEqual(db.query("SELECT HEX(dvalue) FROM vrp_user_data WHERE user_id=71001 AND dkey='vRP:datatable';"),original)
                        return m.apply_schema(db)
                    @staticmethod
                    def verify_schema(db):return m.verify_schema(db)
                report=c.rehearse_schema(work,work,backup,live,VerifiedMigration)
                self.assertTrue(report['restored']);self.assertTrue(report['tableCountsMatch'])
                # Rehearsal did not apply anything to the source database.
                self.assertEqual(live.query("SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='vrp' AND TABLE_NAME='ic_config_schema';"),'0')
                self.assertEqual(live.query("SELECT HEX(dvalue) FROM vrp_user_data WHERE user_id=71001 AND dkey='vRP:datatable';"),original)
                self.assertEqual(m.apply_schema(live)['schemaVersion'],1)
                self.assertEqual(m.verify_schema(live)['triggersVerified'],14)
                self.assertEqual(live.query("SELECT HEX(dvalue) FROM vrp_user_data WHERE user_id=71001 AND dkey='vRP:datatable';"),original)
                live.query("INSERT INTO ic_config_org_deletions(org_name,operation_id,phase,actor_id,payload) VALUES('PendingFixture','fixture-op','prepared',71001,'{}');")
                second_dump=c.run(['docker','exec',name,'sh','-c','MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb-dump -uroot --single-transaction --quick --no-tablespaces --databases vrp'])
                with gzip.open(work/'forward.sql.gz','wt')as stream:stream.write(second_dump)
                class ForwardMigration(VerifiedMigration):
                    @staticmethod
                    def apply_schema(db):
                        outer.assertEqual(db.query("SELECT phase FROM ic_config_org_deletions WHERE operation_id='fixture-op';"),'prepared')
                        return VerifiedMigration.apply_schema(db)
                self.assertTrue(c.rehearse_schema(work,work,work/'forward.sql.gz',live,ForwardMigration)['restored'])
            finally:
                subprocess.run(['docker','rm','-f',name],capture_output=True)
