import contextlib
import importlib.util
import io
from pathlib import Path
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]
SPEC=importlib.util.spec_from_file_location('ic_config_migrate_test',ROOT/'scripts/ic-config-migrate.py')
m=importlib.util.module_from_spec(SPEC);SPEC.loader.exec_module(m)

class SchemaMetadata:
    def __init__(self,defect=None):self.defect=defect;self.applied=False
    def query(self,sql):
        if sql==m.SCHEMA.read_text():self.applied=True;return''
        if 'information_schema.COLUMNS'in sql:
            return'\n'.join(table+'\t'+column for table,columns in m.REQUIRED.items()for column in columns)
        if 'information_schema.TABLES'in sql:
            return'\n'.join(table+'\t'+('MyISAM'if self.defect=='engine'and table=='vrp_user_data'else'InnoDB')for table in m.REQUIRED)
        if 'MAX(version)'in sql:return'1'
        if 'information_schema.TRIGGERS'in sql:
            definitions=m.triggers();rows=[]
            for index,(name,(timing,event,table,body))in enumerate(definitions.items()):
                if self.defect=='missing'and index==0:continue
                if self.defect=='body'and index==0:body='BEGIN SELECT 1; END'
                rows.append('\t'.join((name,timing,event,table,body.encode().hex())))
            return'\n'.join(rows)
        raise AssertionError('Unexpected query')

class ConfigMigrationTests(unittest.TestCase):
    def test_dry_run_never_opens_database_and_apply_needs_stopped_writers(self):
        with patch.object(m,'Database',side_effect=AssertionError('must not connect')),contextlib.redirect_stdout(io.StringIO()):
            result=m.main(['schema','--dry-run'])
            self.assertFalse(result['databaseAccessed'])
            with self.assertRaises(m.MigrationError):m.main(['schema','--apply'])

    def test_verifier_checks_trigger_bodies_and_all_transactional_engines(self):
        self.assertEqual(m.verify_schema(SchemaMetadata())['triggersVerified'],14)
        for defect in ('engine','missing','body'):
            with self.subTest(defect=defect),self.assertRaises(m.MigrationError):m.verify_schema(SchemaMetadata(defect))
        database=SchemaMetadata('engine')
        with self.assertRaises(m.MigrationError):m.apply_schema(database)
        self.assertFalse(database.applied)

    def test_static_carrier_reader_is_reproducible_and_emits_only_abi(self):
        spec=importlib.util.spec_from_file_location('mansion_static_test',ROOT/'scripts/analysis/inspect-mansion-contract.py')
        inspector=importlib.util.module_from_spec(spec);spec.loader.exec_module(inspector)
        report=inspector.inspect(ROOT/'resources/[scriptcore]/m_mansions/server.lua')
        self.assertFalse(report['targetExecuted']);self.assertTrue(report['exhausted'])
        self.assertEqual(report['prototypes'],86)
        bindings={row['export']:row['parameters']for row in report['bindings']}
        self.assertEqual((bindings['getMansions'],bindings['saveMansion'],bindings['removeMansion']),(0,2,1))
        self.assertNotIn('http',str(report).lower())
