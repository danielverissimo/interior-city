import contextlib
import importlib.util
import io
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('ic_admin_migration', ROOT / 'scripts/ic-admin-migrate.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class DatabaseFixture:
    """Small stateful DB boundary; tests guard overwrite/idempotence policy.

    It does not emulate MariaDB transactions or validate SQL dialect.
    """
    def __init__(self):
        self.documents = {}
        self.discipline_ids = set()
        self.subjects = {}
        self.writes = 0
        self.records={table:{} for table in m.RECORD_TABLES.values()}

    def query(self, sql):
        if sql.startswith('SELECT AUTO_INCREMENT'):return '1'
        if sql.startswith('ALTER TABLE ic_admin_calls AUTO_INCREMENT='):return ''
        if 'information_schema.TABLES' in sql:
            return '\n'.join(table + '\tInnoDB' for table in set(m.REQUIRED_TABLES) | {'mirtin_bans', 'mirtin_bans_hwid', 'mirtin_bans_ip'})
        if 'information_schema.COLUMNS' in sql:
            return '\n'.join(table + '\t' + col for table, cols in {**m.REQUIRED_TABLES, 'mirtin_bans': {'owner', 'staff'}}.items() for col in cols)
        if 'MAX(version)' in sql: return '2'
        if sql.startswith('SELECT id,HEX(payload) FROM ic_admin_'):
            table=sql.split(' FROM ')[1].split()[0]
            return '\n'.join(str(key)+'\t'+m.canonical(value).encode().hex() for key,value in self.records[table].items())
        if sql.startswith('SELECT user_id,subject_key'):
            return '\n'.join(str(uid) + '\t' + key for uid, key in self.subjects.items())
        if 'SELECT doc_key,HEX(payload)' in sql:
            return '\n'.join(k + '\t' + m.canonical(v).encode().hex() for k, v in self.documents.items())
        if 'SELECT user_id,kind,starts_at' in sql: return ''
        if 'SELECT COUNT(*) FROM ic_admin_discipline' in sql:
            ids = set(map(int, re.search(r'IN \(([^)]+)\)', sql)[1].split(',')))
            return str(len(ids & self.discipline_ids))
        if sql.startswith('START TRANSACTION'):
            self.writes += 1
            for key, uid in re.findall(r'ic_admin_subjects\(subject_key,user_id\) VALUES \(CONVERT\(0x([0-9a-f]+) USING utf8mb4\),\(SELECT id FROM vrp_users WHERE id=(\d+)\)\)', sql):
                self.subjects.setdefault(int(uid), bytes.fromhex(key).decode())
            for match in re.finditer(r'ic_admin_documents\(doc_key,payload,revision\) VALUES \((CONVERT\(0x[0-9a-f]+ USING utf8mb4\)|\'migration:legacy\'),CONVERT\(0x([0-9a-f]+) USING utf8mb4\),1\)', sql):
                raw_key = match[1]
                key = 'migration:legacy' if raw_key.startswith("'") else bytes.fromhex(re.search(r'0x([0-9a-f]+)', raw_key)[1]).decode()
                self.documents[key] = json.loads(bytes.fromhex(match[2]).decode())
            for table,identifier,payload in re.findall(r'INSERT INTO (ic_admin_calls|ic_admin_ratings|ic_admin_vip_assignments) \(id,[^;]+?VALUES \(CONVERT\(0x([0-9a-f]+) USING utf8mb4\),[^;]*?,CONVERT\(0x([0-9a-f]+) USING utf8mb4\),1\)',sql):
                self.records[table][bytes.fromhex(identifier).decode()]=json.loads(bytes.fromhex(payload).decode())
            self.discipline_ids.update(int(value) for value in re.findall(r'ic_admin_discipline\(id,.*?VALUES \((\d+),', sql))
            return ''
        raise AssertionError('Unexpected SQL fixture operation')


class ICAdminMigrationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.source = self.root / 'legacy'; self.source.mkdir()
        for name in m.FILES: (self.source / name).write_text('')
        (self.source / 'logs_config.json').write_text('{}')
        self.groups = self.root / 'groups.json'
        self.groups.write_text(json.dumps({'groups': [{'name': 'vip_fixture', 'config': {'gtype': 'vip', 'salario': 25, 'title': 'Fixture'}, 'permissions': ['perm.fixture']}]}))
        self.snapshot = self.root / 'snapshot'

    def write(self, name, value):
        (self.source / name).write_text(json.dumps(value))

    def seal(self):
        return m.seal_snapshot(self.source, self.snapshot, self.groups, True)

    def test_snapshot_requires_stopped_writers_and_new_output(self):
        with self.assertRaises(m.MigrationError): m.seal_snapshot(self.source, self.snapshot, self.groups)
        self.seal()
        with self.assertRaises(m.MigrationError): self.seal()

    def test_empty_known_placeholders_have_explicit_defaults(self):
        self.seal(); data = m.build_import(self.snapshot)
        self.assertEqual(data['documents']['vip_assignments'], {'assignments': []})
        self.assertEqual(data['documents']['permissions'], {'actions': {}})
        self.assertNotIn('climate', data['documents'])
        self.assertEqual(data['discipline'], [])

    def test_corrupt_json_rejected_before_snapshot_is_created(self):
        (self.source / 'warnings_data.json').write_text('{broken')
        with self.assertRaises(m.MigrationError): self.seal()
        self.assertFalse(self.snapshot.exists())

    def test_tampering_sealed_file_is_rejected(self):
        self.seal(); (self.snapshot / 'locations.json').write_text('[]')
        with self.assertRaises(m.MigrationError): m.build_import(self.snapshot)

    def test_symlink_cannot_enter_snapshot(self):
        (self.source / 'warnings_data.json').unlink()
        (self.source / 'warnings_data.json').symlink_to(self.groups)
        with self.assertRaises(m.MigrationError): self.seal()

    def test_snapshot_excludes_webhooks_and_reports_only_count(self):
        value = 'https://example.invalid/private-fixture'
        self.write('logs_config.json', {'webhooks': {'sample': value}})
        report = self.seal()
        self.assertEqual(report['privateDestinationsRequireConfiguration'], 1)
        self.assertFalse((self.snapshot / 'logs_config.json').exists())
        self.assertNotIn(value, ''.join(p.read_text() for p in self.snapshot.iterdir()))

    def test_snapshot_files_are_private(self):
        self.seal()
        self.assertEqual(self.snapshot.stat().st_mode & 0o777, 0o700)
        self.assertTrue(all(p.stat().st_mode & 0o777 == 0o600 for p in self.snapshot.iterdir()))

    def test_vip_uses_vrp_salary_and_preserves_expiration(self):
        self.write('vip_packages.json', {'packages': {'vip_fixture': {'items': [{'item': 'fixture', 'amount': 1}], 'vehicles': []}}})
        self.write('vip_assignments.json', {'assignments': [{'id': 'fixture-assignment', 'userId': 12, 'group': 'vip_fixture', 'assignedAt': 1000, 'expiresAt': 2000, 'state': 'active', 'itemsState': 'applied'}]})
        self.seal(); docs = m.build_import(self.snapshot)['documents']
        self.assertEqual(docs['vip_packages']['packages']['vip_fixture']['salary'], 25)
        assignment = docs['vip_assignments']['assignments'][0]
        self.assertEqual(assignment['expiresAt'], 2000)
        self.assertEqual(assignment['itemsState'], 'applied')

    def test_vip_unknown_delivery_state_blocks_import(self):
        self.write('vip_packages.json', {'packages': {'vip_fixture': {}}})
        self.write('vip_assignments.json', {'assignments': [{'userId': 12, 'group': 'vip_fixture', 'assignedAt': 1000, 'expiresAt': 2000}]})
        with self.assertRaisesRegex(m.MigrationError, 'reconciliation'): self.seal()

    def test_vip_cannot_reference_staff_group(self):
        self.groups.write_text(json.dumps({'groups': [{'name': 'vip_fixture', 'config': {'gtype': 'staff'}}]}))
        self.write('vip_packages.json', {'packages': {'vip_fixture': {}}})
        with self.assertRaises(m.MigrationError): self.seal()

    def test_calls_history_is_normalized_and_rating_kept(self):
        self.write('calls_data.json', {'nextId': 3, 'history': [{'id': 2, 'playerId': 12, 'playerName': 'Fixture', 'staffId': 1, 'staffName': 'Staff', 'createdAt': 1000, 'acceptedAt': 1010, 'completedAt': 1020, 'message': 'Fixture call'}], 'evaluations': [{'callId': 2, 'staffId': 1, 'stars': 5, 'message': 'Fixture', 'createdAt': 1030}]})
        self.seal(); calls = m.build_import(self.snapshot)['documents']['calls']
        self.assertEqual(calls['calls'][0]['state'], 'finished')
        self.assertEqual(calls['calls'][0]['requesterId'], 12)
        self.assertEqual(calls['ratings'][0]['stars'], 5)

    def test_rating_requires_existing_call(self):
        self.write('calls_data.json', {'history': [], 'evaluations': [{'callId': 2, 'staffId': 1, 'stars': 5, 'createdAt': 1000}]})
        with self.assertRaises(m.MigrationError): self.seal()

    def test_unknown_nonempty_history_is_not_silently_discarded(self):
        self.write('warnings_data.json', {'unknownFormat': [{'userId': 12}]})
        with self.assertRaises(m.MigrationError): self.seal()

    def test_legacy_rotating_flag_is_preserved(self):
        self.write('environment_state.json',{'weather':'RAIN','hour':17,'rotating':True,'timeFrozen':True,'weatherFrozen':False})
        self.seal();climate=m.build_import(self.snapshot)['documents']['climate']
        self.assertTrue(climate['rotation']);self.assertTrue(climate['freezeTime']);self.assertFalse(climate['freezeWeather'])

    def test_string_boolean_climate_is_rejected(self):
        self.write('environment_state.json', {'weather': 'CLEAR', 'hour': 12, 'freezeTime': 'false'})
        with self.assertRaises(m.MigrationError): self.seal()

    def test_location_categories_are_derived_without_losing_coordinates(self):
        self.write('locations.json', [{'name': 'Fixture', 'category': 'Fixture group', 'x': 1.5, 'y': -2, 'z': 3}])
        self.seal(); locations = m.build_import(self.snapshot)['documents']['locations']
        self.assertEqual(locations['categories'], ['Fixture group'])
        self.assertEqual(locations['locations'][0]['x'], 1.5)

    def test_bad_coordinate_is_rejected(self):
        self.write('locations.json', [{'name': 'Fixture', 'x': '1,2,3', 'y': 2, 'z': 3}])
        with self.assertRaises(m.MigrationError): self.seal()

    def test_permission_role_unknown_is_rejected(self):
        self.write('panel_permissions.json', {'actions': {'view_players': {'stranger': True}}})
        with self.assertRaises(m.MigrationError): self.seal()

    def test_active_warning_needs_restoration_state(self):
        self.write('warnings_data.json', {'warnings': [{'targetId': 12, 'staffId': 1, 'createdAt': 1000, 'expiresAt': 2000, 'state': 'active', 'reason': 'Fixture'}]})
        with self.assertRaises(m.MigrationError): self.seal()

    def test_discipline_history_has_stable_identity(self):
        self.write('warnings_data.json', {'warnings': [{'targetId': 12, 'staffId': 1, 'createdAt': 1000, 'expiresAt': 2000, 'reason': 'Fixture'}]})
        self.seal(); first = m.build_import(self.snapshot); second = m.build_import(self.snapshot)
        self.assertEqual(first['discipline'], second['discipline'])
        self.assertEqual(first['discipline'][0]['state'], 'archived')

    def test_import_is_idempotent_and_verifies_after_apply(self):
        self.seal(); data = m.build_import(self.snapshot); db = DatabaseFixture()
        self.assertTrue(m.apply_import(db, data)['verified'])
        self.assertTrue(m.apply_import(db, data)['verified'])
        self.assertEqual(db.writes, 1)

    def test_import_uses_existing_stable_identity_for_call_and_rating(self):
        self.write('calls_data.json', {'nextId': 3, 'history': [{'id': 2, 'playerId': 12, 'staffId': 1, 'createdAt': 1000, 'completedAt': 1020}], 'evaluations': [{'callId': 2, 'staffId': 1, 'stars': 5, 'createdAt': 1030}]})
        self.seal(); data = m.build_import(self.snapshot); db = DatabaseFixture()
        db.subjects = {12: 'stable-player', 1: 'stable-staff'}
        m.apply_import(db, data)
        calls = db.documents['calls']
        self.assertEqual(calls['calls'][0]['requesterSubject'], 'stable-player')
        self.assertEqual(calls['calls'][0]['acceptedSubject'], 'stable-staff')
        self.assertEqual(calls['ratings'][0]['staffSubject'], 'stable-staff')
        self.assertTrue(m.apply_import(db, data)['verified'])

    def test_divergent_data_is_never_overwritten_implicitly(self):
        self.seal(); data = m.build_import(self.snapshot); db = DatabaseFixture()
        db.documents['permissions'] = {'actions': {'view_players': {'admin': False}}}
        with self.assertRaises(m.MigrationError): m.apply_import(db, data)
        self.assertEqual(db.writes, 0)

    def test_delta_cannot_overwrite_runtime_edits(self):
        self.seal(); data = m.build_import(self.snapshot); db = DatabaseFixture(); m.apply_import(db, data)
        db.documents['permissions'] = {'actions': {'view_players': {'admin': False}}}
        with self.assertRaises(m.MigrationError): m.apply_import(db, data, replace_imported=True)

    def test_dry_run_never_connects_to_database_or_writes_source(self):
        self.seal(); before = {p.name: p.read_bytes() for p in self.snapshot.iterdir()}
        with patch.object(m, 'Database', side_effect=AssertionError('DB must not be used')):
            with contextlib.redirect_stdout(io.StringIO()): report = m.main(['import', '--snapshot', str(self.snapshot), '--dry-run'])
        self.assertIn('snapshotDigest', report)
        self.assertEqual(before, {p.name: p.read_bytes() for p in self.snapshot.iterdir()})

    def test_v2_record_promotion_refuses_unknown_states_and_orphan_ratings(self):
        call={'id':1,'requesterId':12,'requesterSubject':'stable','department':'staff','state':'unknown','createdAt':1}
        with self.assertRaises(m.MigrationError):m.record_statements({'calls':{'calls':[call]}})
        with self.assertRaises(m.MigrationError):m.record_statements({'calls':{'ratings':[{'callId':9,'stars':5}]}})
        with self.assertRaises(m.MigrationError):m.record_statements({'calls':{'calls':[{}]}})

    def test_sql_encodes_values_and_not_sql_fragments(self):
        encoded = m.sql_text("fixture'); DROP TABLE example; --")
        self.assertNotIn('DROP', encoded)
        self.assertRegex(encoded, r'^CONVERT\(0x[0-9a-f]+ USING utf8mb4\)$')

    def test_schema_only_adds_admin_tables_and_required_ban_columns(self):
        schema = m.SCHEMA.read_text()
        self.assertNotRegex(schema.upper(), r'\b(DROP|DELETE|TRUNCATE)\s')
        self.assertIn('ADD COLUMN IF NOT EXISTS owner', schema)
        self.assertIn('ADD COLUMN IF NOT EXISTS staff', schema)
        self.assertEqual(schema.count('ENGINE=InnoDB'),6)
        self.assertIn('CREATE TABLE IF NOT EXISTS ic_admin_ratings LIKE ic_admin_calls',m.RECORD_SCHEMA.read_text())
        self.assertEqual(len(m.REQUIRED_TABLES),9)

    def test_schema_verification_refuses_nontransactional_required_table(self):
        db = DatabaseFixture()
        query = db.query
        def with_nontransactional_table(sql):
            value = query(sql)
            return value.replace('mirtin_bans\tInnoDB', 'mirtin_bans\tMyISAM') if 'information_schema.TABLES' in sql else value
        db.query = with_nontransactional_table
        with self.assertRaisesRegex(m.MigrationError, 'InnoDB'): m.verify_schema(db)

    @unittest.skipUnless(shutil.which('lua'), 'Lua interpreter unavailable')
    def test_service_contract_harness(self):
        result = subprocess.run(['lua', 'tests/ic_admin_services.lua', '.'], cwd=ROOT, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == '__main__': unittest.main()
