#!/usr/bin/env python3
"""Explicit IC Admin schema and sealed legacy-data migration (Python stdlib).

Dry runs do not connect to a database. Database commands use the MariaDB client
already inside Compose; credentials and SQL data never appear in command args.
"""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = ROOT / 'database/ic_admin/001_initial.sql'
RECORD_SCHEMA = ROOT / 'database/ic_admin/002_records.sql'
RECORD_TABLES = {'calls':'ic_admin_calls','ratings':'ic_admin_ratings','vip_assignments':'ic_admin_vip_assignments'}
FILES = ('panel_permissions.json', 'vip_packages.json', 'vip_assignments.json',
         'locations.json', 'location_categories.json', 'calls_data.json',
         'ban_history.json', 'warnings_data.json', 'environment_state.json', 'vehicles.json')
REQUIRED_TABLES = {
    'ic_admin_schema': {'version', 'applied_at'},
    'ic_admin_documents': {'doc_key', 'payload', 'revision'},
    'ic_admin_operations': {'operation_key', 'actor_id', 'method', 'payload', 'state', 'result', 'created_at', 'updated_at'},
    'ic_admin_audit': {'id', 'action', 'actor_id', 'actor_name', 'target_id', 'target_name', 'payload', 'created_at'},
    'ic_admin_subjects': {'subject_key', 'user_id', 'created_at'},
    'ic_admin_discipline': {'id', 'subject_key', 'user_id', 'actor_id', 'kind', 'reason', 'starts_at', 'ends_at', 'state', 'return_state'},
}

REQUIRED_TABLES.update({table: {'id','owner_id','subject_key','actor_id','actor_subject','state','department','created_at','expires_at','payload','revision'} for table in RECORD_TABLES.values()})


class MigrationError(ValueError):
    """Messages only contain fixed diagnostics and file names, never input values."""


def canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':'), allow_nan=False)


def digest(value):
    raw = value if isinstance(value, bytes) else canonical(value).encode()
    return hashlib.sha256(raw).hexdigest()


def read_json(path, empty=None):
    if path.is_symlink() or not path.is_file():
        raise MigrationError('Expected a regular snapshot file: ' + path.name)
    if path.stat().st_size > 32 * 1024 * 1024:
        raise MigrationError('Snapshot file exceeds migration bound: ' + path.name)
    raw = path.read_bytes()
    if not raw.strip() and empty is not None:
        return empty
    try:
        return json.loads(raw.decode('utf-8-sig'), parse_constant=lambda _: (_ for _ in ()).throw(ValueError()))
    except (ValueError, UnicodeError):
        raise MigrationError('Invalid JSON: ' + path.name) from None


def obj(value, label):
    if not isinstance(value, dict):
        raise MigrationError('Expected object: ' + label)
    return value


def array(value, label):
    if not isinstance(value, list):
        raise MigrationError('Expected array: ' + label)
    return value


def integer(value, minimum=0, maximum=2147483647):
    if isinstance(value, bool):
        raise MigrationError('Invalid integer in legacy record')
    try:
        n = int(value)
    except (ValueError, TypeError, OverflowError):
        raise MigrationError('Missing or invalid integer in legacy record') from None
    if str(n) != str(value) and not (isinstance(value, float) and value == n):
        raise MigrationError('Invalid integer in legacy record')
    if not minimum <= n <= maximum:
        raise MigrationError('Integer outside migration bounds')
    return n


def text(value, length=500, required=True):
    if not isinstance(value, str) or len(value) > length or (required and not value.strip()):
        raise MigrationError('Missing or invalid text in legacy record')
    if any(ord(c) < 32 and c not in '\n\t' for c in value):
        raise MigrationError('Control character in legacy text')
    return value.strip()


def number(value):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or abs(value) > 100000:
        raise MigrationError('Invalid coordinate in legacy record')
    return value


def boolean(value):
    if not isinstance(value, bool): raise MigrationError('Expected boolean in legacy record')
    return value


def first(row, *keys, default=None):
    for key in keys:
        if key in row:
            return row[key]
    return default


def seal_snapshot(source, output, groups, writers_stopped=False):
    if not writers_stopped:
        raise MigrationError('Snapshot requires explicit --writers-stopped attestation')
    source, output, groups = Path(source).resolve(), Path(output), Path(groups)
    if output.exists() or output.is_symlink():
        raise MigrationError('Snapshot output must be a new directory')
    payloads = {}
    for name in FILES:
        path = source / name
        if path.is_symlink() or not path.is_file():
            raise MigrationError('Missing legacy snapshot file: ' + name)
        payloads[name] = path.read_bytes()
        if len(payloads[name]) > 32 * 1024 * 1024:
            raise MigrationError('Snapshot file exceeds migration bound: ' + name)
    read_json(groups)
    payloads['groups.json'] = groups.read_bytes()
    # Never copy webhook URLs into a portable snapshot.
    private_count = 0
    hooks = source / 'logs_config.json'
    if hooks.exists():
        values = read_json(hooks, {})
        def count_values(value):
            if isinstance(value, dict): return sum(count_values(v) for v in value.values())
            if isinstance(value, list): return sum(count_values(v) for v in value)
            return int(isinstance(value, str) and value.startswith('https://'))
        private_count = count_values(values)
    # Validate the complete captured bytes in a private temporary tree first.
    manifest = {'format': 1, 'writersStopped': True,
                'files': {name: digest(raw) for name, raw in payloads.items()},
                'privateDestinationsRequireConfiguration': private_count}
    with tempfile.TemporaryDirectory() as tmp:
        temp = Path(tmp)
        for name, raw in payloads.items(): (temp / name).write_bytes(raw)
        (temp / 'snapshot.json').write_text(canonical(manifest))
        build_import(temp)
    output.mkdir(mode=0o700, parents=True)
    for name, raw in payloads.items():
        path = output / name
        path.write_bytes(raw); path.chmod(0o600)
    (output / 'snapshot.json').write_text(canonical(manifest) + '\n')
    (output / 'snapshot.json').chmod(0o600)
    return {'files': len(payloads), 'snapshotDigest': digest(manifest), 'privateDestinationsRequireConfiguration': private_count}


def build_import(snapshot):
    snapshot = Path(snapshot)
    if snapshot.is_symlink(): raise MigrationError('Snapshot directory must not be a symlink')
    manifest = obj(read_json(snapshot / 'snapshot.json'), 'snapshot manifest')
    if manifest.get('format') != 1 or manifest.get('writersStopped') is not True:
        raise MigrationError('A sealed format-1 snapshot with stopped writers is required')
    hashes = obj(manifest.get('files'), 'snapshot files')
    if set(hashes) != set(FILES) | {'groups.json'}:
        raise MigrationError('Snapshot inventory does not match the supported file set')
    for name, checksum in hashes.items():
        path = snapshot / name
        if path.is_symlink() or not path.is_file() or path.stat().st_size > 32 * 1024 * 1024:
            raise MigrationError('Invalid snapshot member: ' + name)
        if checksum != digest(path.read_bytes()):
            raise MigrationError('Snapshot checksum mismatch: ' + name)
    source_digest = digest(manifest)
    groups_list = array(obj(read_json(snapshot / 'groups.json'), 'groups').get('groups'), 'groups')
    groups = {text(obj(g, 'group').get('name'), 80): g for g in groups_list}
    if len(groups) != len(groups_list): raise MigrationError('Duplicate vRP group identity')
    docs = {}

    permissions = obj(read_json(snapshot / 'panel_permissions.json', {}), 'permissions')
    perms = permissions.get('actions', permissions.get('functions', permissions.get('access', permissions)))
    perms = obj(perms, 'permission actions')
    normalized = {}
    for key, roles in perms.items():
        if not re.fullmatch(r'[a-z][a-z0-9_]{0,95}', key): raise MigrationError('Invalid legacy permission key')
        roles = obj(roles, 'permission roles')
        if set(roles) - {'admin', 'moderador', 'suporte', 'dono', 'developer'}: raise MigrationError('Unknown legacy permission role')
        if any(not isinstance(v, bool) for v in roles.values()): raise MigrationError('Legacy permission access must be boolean')
        normalized[key] = {r: roles.get(r, r == 'admin') for r in ('admin', 'moderador', 'suporte')}
    docs['permissions'] = {'actions': normalized}

    packages = obj(obj(read_json(snapshot / 'vip_packages.json', {'packages': {}}), 'VIP packages').get('packages'), 'VIP packages')
    out_packages = {}
    for group, package in packages.items():
        text(group, 80); package = obj(package, 'VIP package')
        definition = groups.get(group)
        if not definition: raise MigrationError('VIP package references missing vRP group')
        cfg = obj(definition.get('config', {}), 'VIP group config')
        if str(cfg.get('gtype', '')).lower() != 'vip': raise MigrationError('VIP package references a non-VIP vRP group')
        items = []
        for item in array(package.get('items', []), 'VIP items'):
            item = obj(item, 'VIP item')
            items.append({'item': text(item.get('item'), 100), 'amount': integer(item.get('amount'), 1, 100000000)})
        vehicles = []
        for car in array(package.get('vehicles', []), 'VIP vehicles'):
            car = obj(car, 'VIP vehicle'); spawn = text(car.get('spawn'), 80)
            vehicles.append({'spawn': spawn, 'name': text(car.get('name', spawn), 100), 'category': text(car.get('category', 'game'), 40)})
        choices = integer(package.get('vehicleChoices', 0), 0, len(vehicles))
        out_packages[group] = {'group': group, 'title': text(package.get('title', cfg.get('title', group)), 100),
            'salary': integer(package.get('salary', cfg.get('salario', 0))), 'items': items, 'vehicles': vehicles,
            'vehicleChoices': choices, 'garageSlots': integer(package.get('garageSlots', 0), 0, 1000)}
    docs['vip_packages'] = {'packages': out_packages}

    assignments = obj(read_json(snapshot / 'vip_assignments.json', {'assignments': []}), 'VIP assignments')
    if assignments and 'assignments' not in assignments: raise MigrationError('Unrecognized VIP assignments format')
    assignment_rows = assignments.get('assignments', [])
    if isinstance(assignment_rows, dict): assignment_rows = list(assignment_rows.values())
    out_assignments, seen_assignments = [], set()
    for row in array(assignment_rows, 'VIP assignments'):
        row = obj(row, 'VIP assignment')
        uid = integer(first(row, 'userId', 'targetId', 'user_id'), 1)
        group = text(row.get('group'), 80)
        if group not in out_packages: raise MigrationError('VIP assignment references missing package')
        assigned = integer(first(row, 'assignedAt', 'createdAt'), 1, 9999999999)
        expires = integer(row.get('expiresAt'), assigned, 9999999999)
        assignment_id = str(row.get('id') or digest([uid, group, assigned])[:24])
        if assignment_id in seen_assignments: raise MigrationError('Duplicate VIP assignment identity')
        seen_assignments.add(assignment_id)
        state = row.get('state')
        items_state = row.get('itemsState')
        if state not in ('active', 'uncertain', 'archived') or items_state not in ('pending', 'applying', 'applied', 'uncertain'):
            raise MigrationError('VIP assignment benefit state requires explicit reconciliation')
        claims = array(row.get('claims', []), 'VIP claims')
        for claim in claims:
            obj(claim, 'VIP claim'); text(claim.get('vehicle'), 80)
            if claim.get('state') not in ('applying', 'applied', 'uncertain'): raise MigrationError('Unknown VIP claim state')
        package = out_packages[group]
        out_assignments.append({'id': assignment_id, 'userId': uid, 'group': group, 'assignedAt': assigned,
            'expiresAt': expires, 'state': state, 'itemsState': items_state, 'claims': claims,
            'vehicleChoices': integer(row.get('vehicleChoices', package['vehicleChoices']), 0, len(package['vehicles'])),
            'vehicles': package['vehicles'], 'garageSlots': package['garageSlots'], 'actorId': integer(row.get('actorId', 0))})
    docs['vip_assignments'] = {'assignments': out_assignments}

    locations = read_json(snapshot / 'locations.json', [])
    if isinstance(locations, dict): locations = locations.get('locations')
    categories = read_json(snapshot / 'location_categories.json', [])
    if isinstance(categories, dict): categories = categories.get('categories')
    out_categories = [text(c if isinstance(c, str) else obj(c, 'location category').get('name'), 80) for c in array(categories, 'location categories')]
    out_locations = []
    for index, row in enumerate(array(locations, 'locations'), 1):
        row = obj(row, 'location'); category = text(row.get('category', 'Geral'), 80)
        if category not in out_categories: out_categories.append(category)
        out_locations.append({'id': integer(row.get('id', index), 1), 'name': text(row.get('name'), 100), 'category': category,
                              'x': number(row.get('x')), 'y': number(row.get('y')), 'z': number(row.get('z'))})
    if len({r['id'] for r in out_locations}) != len(out_locations): raise MigrationError('Duplicate location identity')
    docs['locations'] = {'locations': out_locations, 'categories': out_categories}

    calls = obj(read_json(snapshot / 'calls_data.json', {'nextId': 1, 'history': [], 'evaluations': []}), 'calls')
    if set(calls) - {'nextId', 'calls', 'history', 'openCalls', 'evaluations', 'ratings'}: raise MigrationError('Unrecognized calls format')
    source_calls = calls.get('calls', None)
    if source_calls is None:
        source_calls = array(calls.get('history', []), 'call history') + array(calls.get('openCalls', []), 'open calls')
    out_calls, call_ids = [], set()
    for row in array(source_calls, 'calls'):
        row = obj(row, 'call'); cid = integer(row.get('id'), 1)
        if cid in call_ids: raise MigrationError('Duplicate call identity')
        call_ids.add(cid)
        state = row.get('state', 'finished' if row.get('completedAt') else ('accepted' if row.get('staffId') else 'open'))
        if state not in ('open', 'accepted', 'finished', 'cancelled'): raise MigrationError('Unknown call state')
        department = row.get('department', 'staff')
        if department not in ('staff', 'police', 'mechanic', 'hospital'): raise MigrationError('Unknown call department')
        out = {'id': cid, 'requesterId': integer(first(row, 'requesterId', 'playerId'), 1),
               'requesterName': text(first(row, 'requesterName', 'playerName', default='Jogador'), 128),
               'department': department, 'message': text(row.get('message', 'Chamado importado'), 500),
               'state': state, 'createdAt': integer(row.get('createdAt'), 1, 9999999999)}
        if first(row, 'acceptedBy', 'staffId') is not None:
            out.update(acceptedBy=integer(first(row, 'acceptedBy', 'staffId'), 1), acceptedName=text(first(row, 'acceptedName', 'staffName', default='Staff'), 128))
        for field, old in [('acceptedAt', 'acceptedAt'), ('finishedAt', 'completedAt')]:
            value = first(row, field, old)
            if value is not None: out[field] = integer(value, 1, 9999999999)
        out_calls.append(out)
    ratings = []
    rated_calls = set()
    for row in array(calls.get('ratings', calls.get('evaluations', [])), 'call ratings'):
        row = obj(row, 'call rating'); cid = integer(row.get('callId'), 1)
        if cid not in call_ids: raise MigrationError('Rating references missing call')
        matching = next(call for call in out_calls if call['id'] == cid)
        if cid in rated_calls or matching.get('acceptedBy') != integer(row.get('staffId'), 1) or matching['state'] != 'finished':
            raise MigrationError('Rating does not match a unique completed staff attendance')
        rated_calls.add(cid)
        ratings.append({'callId': cid, 'staffId': integer(row.get('staffId'), 1), 'stars': integer(row.get('stars'), 1, 5),
                        'message': text(row.get('message', ''), 500, False), 'createdAt': integer(row.get('createdAt'), 1, 9999999999)})
    docs['calls'] = {'nextId': max(integer(calls.get('nextId', 1), 1), max(call_ids, default=0) + 1), 'calls': out_calls, 'ratings': ratings}

    climate = obj(read_json(snapshot / 'environment_state.json', {}), 'climate')
    if climate:
        weather = text(first(climate, 'weather', 'currentWeather'), 30)
        if weather not in ('EXTRASUNNY', 'CLEAR', 'NEUTRAL', 'SMOG', 'FOGGY', 'OVERCAST', 'CLOUDS', 'CLEARING', 'RAIN', 'THUNDER', 'SNOW', 'BLIZZARD', 'SNOWLIGHT', 'XMAS', 'HALLOWEEN'):
            raise MigrationError('Unknown legacy climate')
        docs['climate'] = {'weather': weather, 'hour': integer(first(climate, 'hour', 'currentHour'), 0, 23),
            'minute': integer(first(climate, 'minute', 'currentMinute', default=0), 0, 59),
            'freezeWeather': boolean(first(climate, 'freezeWeather', 'weatherFrozen', default=True)),
            'freezeTime': boolean(first(climate, 'freezeTime', 'timeFrozen', default=False)), 'rotation': boolean(climate.get('rotation', False))}

    vehicles = read_json(snapshot / 'vehicles.json', [])
    if vehicles: docs['legacy_vehicle_catalog'] = vehicles

    discipline = []
    for filename, kind in [('warnings_data.json', 'warning'), ('ban_history.json', 'ban')]:
        values = obj(read_json(snapshot / filename, {'entries': []}), filename)
        if values and not any(key in values for key in ('warnings', 'entries')): raise MigrationError('Unrecognized discipline history format')
        rows = values.get('warnings', values.get('entries', []))
        if isinstance(rows, dict): rows = list(rows.values())
        for row in array(rows, filename):
            row = obj(row, 'discipline record')
            uid = integer(first(row, 'userId', 'targetId', 'user_id', 'target_id'), 1)
            started = integer(first(row, 'startsAt', 'createdAt', 'timestamp'), 1, 9999999999)
            ends = first(row, 'endsAt', 'expiresAt')
            if ends is not None: ends = integer(ends, started, 9999999999)
            actual_kind = 'unban' if kind == 'ban' and first(row, 'action', 'type', default='ban') in ('unban', 'desban') else kind
            state = 'archived'
            restore = row.get('returnState', row.get('return_state'))
            if kind == 'warning' and row.get('state', row.get('status')) == 'active':
                if ends is None or not isinstance(restore, dict): raise MigrationError('Active warning requires expiry and restoration state')
                coords = obj(restore.get('coords'), 'warning restoration coordinates')
                restore = {'coords': {k: number(coords.get(k)) for k in ('x', 'y', 'z')}, 'bucket': integer(restore.get('bucket', 0))}
                state = 'active'
            record = {'user_id': uid, 'actor_id': integer(first(row, 'actorId', 'staffId', default=0)), 'kind': actual_kind,
                      'reason': text(row.get('reason', row.get('motivo')), 4000), 'starts_at': started,
                      'ends_at': ends, 'state': state, 'return_state': restore}
            record['id'] = int(digest(record)[:12], 16)
            discipline.append(record)
    if len({r['id'] for r in discipline}) != len(discipline): raise MigrationError('Duplicate discipline identity')
    return {'snapshotDigest': source_digest, 'documents': docs, 'discipline': discipline,
            'privateDestinationsRequireConfiguration': integer(manifest.get('privateDestinationsRequireConfiguration', 0))}


def sql_text(value):
    return 'CONVERT(0x' + str(value).encode().hex() + ' USING utf8mb4)' if value else "''"


class Database:
    def __init__(self, args):
        if not args.env_file or not args.project_name:
            raise MigrationError('Database access requires explicit --env-file and --project-name')
        if not re.fullmatch(r'[a-z0-9][a-z0-9_-]{0,90}', args.project_name): raise MigrationError('Invalid Compose project name')
        env_file = Path(args.env_file).resolve()
        if not env_file.is_file(): raise MigrationError('Compose environment file is missing')
        self.command = ['docker', 'compose', '--env-file', str(env_file), '--project-directory', str(Path(args.project_directory).resolve()), '-p', args.project_name]
        for path in args.compose_file or [str(ROOT / 'compose.yaml')]: self.command += ['-f', str(Path(path).resolve())]
        self.command += ['exec', '-T', 'db', 'sh', '-c',
                         'MYSQL_PWD="$(cat /run/secrets/db_root_password)" exec mariadb --user=root --batch --raw --skip-column-names --binary-mode --default-character-set=utf8mb4 --database="$MARIADB_DATABASE"']

    def query(self, sql):
        result = subprocess.run(self.command, input=sql, text=True, capture_output=True, cwd=ROOT)
        if result.returncode: raise MigrationError('Database command failed; query values and database diagnostics were suppressed')
        return result.stdout.rstrip('\r\n')


def verify_schema(db, version=2):
    rows = db.query("SELECT TABLE_NAME,COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND (TABLE_NAME LIKE 'ic_admin_%' OR TABLE_NAME='mirtin_bans');")
    found = {}
    for line in rows.splitlines():
        parts = line.split('\t')
        if len(parts) == 2: found.setdefault(parts[0], set()).add(parts[1])
    for table, columns in {**REQUIRED_TABLES, 'mirtin_bans': {'owner', 'staff'}}.items():
        if not columns <= found.get(table, set()): raise MigrationError('Required schema is missing or incomplete: ' + table)
    transactional = set(REQUIRED_TABLES) | {'mirtin_bans', 'mirtin_bans_hwid', 'mirtin_bans_ip'}
    engines = {}
    rows = db.query('SELECT TABLE_NAME,ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN (' + ','.join(sql_text(table) for table in sorted(transactional)) + ');')
    for line in rows.splitlines():
        parts = line.split('\t')
        if len(parts) == 2: engines[parts[0]] = parts[1]
    if any(engines.get(table) != 'InnoDB' for table in transactional):
        raise MigrationError('Required migration tables must use InnoDB; explicit engine reconciliation is required')
    if db.query('SELECT MAX(version) FROM ic_admin_schema;') != str(version): raise MigrationError('Unsupported IC Admin schema version')
    return {'schemaVersion': version, 'tablesVerified': len(REQUIRED_TABLES)}


def read_documents(db, keys, records=True):
    rows = db.query('SELECT doc_key,HEX(payload) FROM ic_admin_documents WHERE doc_key IN (' + ','.join(sql_text(k) for k in keys) + ');')
    found = {}
    for line in rows.splitlines():
        key, raw = line.split('\t', 1)
        try: found[key] = json.loads(bytes.fromhex(raw).decode())
        except (ValueError, UnicodeError): raise MigrationError('Existing document is not valid JSON') from None
    if records:
        for key in ('calls','vip_assignments'):
            if key not in keys: continue
            domains=('calls','ratings') if key=='calls' else ('vip_assignments',)
            data={}
            for domain in domains:
                values=[]
                for line in db.query('SELECT id,HEX(payload) FROM '+RECORD_TABLES[domain]+' ORDER BY id;').splitlines():
                    identifier,raw=line.split('\t',1)
                    value=json.loads(bytes.fromhex(raw).decode())
                    if domain=='ratings': value.pop('id',None)
                    else: value.setdefault('id',int(identifier) if domain=='calls' else identifier)
                    values.append(value)
                data['assignments' if domain=='vip_assignments' else domain]=values
            if key=='calls': data['nextId']=max((found.get(key) or {}).get('nextId',1),max((row['id'] for row in data['calls']),default=0)+1)
            if key in found or any(data.get(name) for name in ('calls','ratings','assignments')): found[key]=data
    return found


def record_statements(docs, update=False):
    statements=[]
    calls=array(obj(docs.get('calls',{}),'calls').get('calls',[]),'calls')
    for row in calls: integer(obj(row,'call').get('id'),1,9007199254740991)
    by_call={row['id']:row for row in calls}
    if len(by_call)!=len(calls): raise MigrationError('Duplicate existing call identity')
    for domain,values in (('calls',calls),('ratings',docs.get('calls',{}).get('ratings',[])),('vip_assignments',docs.get('vip_assignments',{}).get('assignments',[]))):
        for row in array(values,'administrative records'):
            obj(row,'administrative record')
            if len(canonical(row).encode())>1000000: raise MigrationError('Administrative record exceeds row bound')
            identifier=row.get('id',row.get('callId'))
            if domain in ('calls','ratings'): integer(identifier,1,9007199254740991)
            else: text(str(identifier),96)
            if domain=='calls':
                if row.get('state') not in {'open','accepted','finished','cancelled'} or row.get('department') not in {'staff','police','mechanic','hospital'}: raise MigrationError('Invalid existing call state or department')
                integer(row.get('requesterId'),1);text(row.get('requesterSubject'),96)
            if domain=='vip_assignments':
                if row.get('state') not in {'active','expired','archived','uncertain','applying'}: raise MigrationError('Invalid existing VIP state')
                integer(row.get('userId'),1);text(row.get('subjectKey'),96);text(row.get('group'),80)
            if domain=='ratings':
                if row.get('callId') not in by_call: raise MigrationError('Existing rating has no call')
                integer(row.get('stars'),1,5)
            if domain=='calls': metadata=(row['requesterId'],row.get('requesterSubject',''),row.get('acceptedBy',0),row.get('acceptedSubject',''),row['state'],row['department'],row.get('createdAt',0),0)
            elif domain=='ratings':
                call=by_call.get(row['callId'],{})
                row=dict(row,requesterId=call.get('requesterId',0),requesterSubject=call.get('requesterSubject',''))
                metadata=(call.get('requesterId',0),call.get('requesterSubject',''),row.get('staffId',0),row.get('staffSubject',''),'rated','staff',row.get('createdAt',0),0)
            else: metadata=(row['userId'],row.get('subjectKey',''),row.get('actorId',0),'',row['state'],row['group'],row.get('assignedAt',0),row.get('expiresAt',0))
            identifier=row.get('id',row.get('callId'))
            fields='id,owner_id,subject_key,actor_id,actor_subject,state,department,created_at,expires_at,payload,revision'
            values=[sql_text(str(identifier))]+[str(v) if isinstance(v,int) else sql_text(v) for v in metadata]+[sql_text(canonical(row)),'1']
            suffix=' ON DUPLICATE KEY UPDATE '+','.join(f'{field}=VALUES({field})' for field in fields.split(',')[1:-1])+',revision=revision+1' if update else ''
            statements.append('INSERT INTO '+RECORD_TABLES[domain]+' ('+fields+') VALUES ('+','.join(values)+')'+suffix+';')
    return statements


def apply_schema(db):
    db.query(SCHEMA.read_text())
    db.query(RECORD_SCHEMA.read_text())
    version=db.query('SELECT MAX(version) FROM ic_admin_schema;')
    if version=='1':
        verify_schema(db,version=1)
        legacy=read_documents(db,['calls','vip_assignments'],records=False)
        # Promotion is all-or-nothing. Existing divergent record IDs abort without overwriting.
        statements=record_statements(legacy)
        next_id=legacy.get('calls',{}).get('nextId',1)
        db.query('ALTER TABLE ic_admin_calls AUTO_INCREMENT='+str(integer(next_id,1))+';')
        db.query('\n'.join(['START TRANSACTION;']+statements+['INSERT INTO ic_admin_schema(version) VALUES (2);','COMMIT;']))
    return verify_schema(db)


def read_discipline(db, records):
    if not records: return {}
    ids = ','.join(str(row['id']) for row in records)
    sql = ('SELECT id,user_id,actor_id,kind,HEX(reason),starts_at,IFNULL(ends_at,\'\'),state,'
           'IFNULL(HEX(return_state),\'NULL\') FROM ic_admin_discipline WHERE id IN (' + ids + ');')
    found = {}
    for line in db.query(sql).splitlines():
        columns = line.split('\t')
        if len(columns) != 9: raise MigrationError('Historical record verification returned an invalid row')
        key, uid, actor, kind, reason, start, end, state, restore = columns
        try:
            found[int(key)] = {'id': int(key), 'user_id': int(uid), 'actor_id': int(actor), 'kind': kind,
                'reason': bytes.fromhex(reason).decode(), 'starts_at': int(start), 'ends_at': int(end) if end else None,
                'state': state, 'return_state': json.loads(bytes.fromhex(restore).decode()) if restore and restore!='NULL' else None}
        except (ValueError, UnicodeError): raise MigrationError('Historical record verification failed') from None
    return found


def bind_subjects(db, imported):
    """Bind numeric legacy IDs to current stable identities before hashing docs."""
    imported = json.loads(canonical(imported))
    docs = imported['documents']
    assignments = docs.get('vip_assignments', {}).get('assignments', [])
    calls = docs.get('calls', {}).get('calls', [])
    ids = {row['user_id'] for row in imported['discipline']}
    ids.update(row['userId'] for row in assignments)
    for call in calls:
        ids.add(call['requesterId'])
        if call.get('acceptedBy'): ids.add(call['acceptedBy'])
    mapping = {}
    if ids:
        rows = db.query('SELECT user_id,subject_key FROM ic_admin_subjects WHERE user_id IN (' + ','.join(str(uid) for uid in sorted(ids)) + ');')
        for line in rows.splitlines():
            values = line.split('\t')
            if len(values) != 2: raise MigrationError('Stable identity verification returned an invalid row')
            mapping[integer(values[0], 1)] = text(values[1], 96)
    for uid in ids: mapping.setdefault(uid, 'legacy:' + str(uid) + ':' + imported['snapshotDigest'][:16])
    for row in assignments: row['subjectKey'] = mapping[row['userId']]
    by_call = {}
    for call in calls:
        call['requesterSubject'] = mapping[call['requesterId']]
        if call.get('acceptedBy'): call['acceptedSubject'] = mapping[call['acceptedBy']]
        by_call[call['id']] = call
    assignments.sort(key=lambda row:str(row['id']))
    calls.sort(key=lambda row:row['id'])
    docs.get('calls', {}).get('ratings', []).sort(key=lambda row:row['callId'])
    for rating in docs.get('calls', {}).get('ratings', []):
        call = by_call.get(rating['callId'], {})
        if call.get('acceptedSubject'): rating['staffSubject'] = call['acceptedSubject']
        rating['requesterId']=call.get('requesterId',0);rating['requesterSubject']=call.get('requesterSubject','')
    return imported, mapping


def apply_import(db, imported, replace_imported=False, verify=False):
    verify_schema(db)
    imported, subjects = bind_subjects(db, imported)
    docs, records = imported['documents'], imported['discipline']
    existing = read_documents(db, list(docs) + ['migration:legacy'])
    marker = existing.get('migration:legacy')
    expected = {key: digest(value) for key, value in docs.items()}
    history = read_discipline(db, records)
    if verify:
        if not marker or marker.get('snapshotDigest') != imported['snapshotDigest']: raise MigrationError('Snapshot migration marker does not match')
        if any(key not in existing or digest(existing[key]) != checksum for key, checksum in expected.items()): raise MigrationError('Imported document verification failed')
        if any(history.get(row['id']) != row for row in records): raise MigrationError('Imported discipline values do not match')
        return {'verified': True, 'documents': len(docs), 'discipline': len(records)}
    for key, value in docs.items():
        if key in existing and digest(existing[key]) != expected[key]:
            if not replace_imported or not marker or marker.get('documentHashes', {}).get(key) != digest(existing[key]):
                raise MigrationError('Destination contains divergent data; explicit reconciliation required: ' + key)
    if marker and marker.get('snapshotDigest') != imported['snapshotDigest'] and not replace_imported:
        raise MigrationError('Different snapshot already imported; review final delta with --replace-imported')
    if marker and marker.get('snapshotDigest') == imported['snapshotDigest']:
        return apply_import(db, imported, verify=True)
    # Deterministic imported IDs avoid duplicate historical records on a delta.
    for row in records:
        if row['id'] in history and history[row['id']] != row:
            raise MigrationError('Historical record identity collision; reconciliation required')
    statements = ['START TRANSACTION;']
    for uid, subject in sorted(subjects.items()):
        statements.append('INSERT IGNORE INTO ic_admin_subjects(subject_key,user_id) VALUES (' + sql_text(subject) + ',(SELECT id FROM vrp_users WHERE id=' + str(uid) + '));')
    for key, value in docs.items():
        statements.append('INSERT INTO ic_admin_documents(doc_key,payload,revision) VALUES (' + sql_text(key) + ',' + sql_text(canonical(value)) + ',1) ON DUPLICATE KEY UPDATE revision=revision+IF(payload<>VALUES(payload),1,0),payload=VALUES(payload);')
    for row in records:
        values = [str(row['id']), sql_text(subjects[row['user_id']]), str(row['user_id']), str(row['actor_id']), sql_text(row['kind']), sql_text(row['reason']), str(row['starts_at']), str(row['ends_at']) if row['ends_at'] else 'NULL', sql_text(row['state']), sql_text(canonical(row['return_state'])) if row['return_state'] else 'NULL']
        statements.append('INSERT IGNORE INTO ic_admin_discipline(id,subject_key,user_id,actor_id,kind,reason,starts_at,ends_at,state,return_state) VALUES (' + ','.join(values) + ');')
    metadata = {'snapshotDigest': imported['snapshotDigest'], 'documentHashes': expected, 'disciplineCount': len(records)}
    statements.append('INSERT INTO ic_admin_documents(doc_key,payload,revision) VALUES (\'migration:legacy\',' + sql_text(canonical(metadata)) + ',1) ON DUPLICATE KEY UPDATE payload=VALUES(payload),revision=revision+1;')
    statements.extend(record_statements(docs,update=True))
    statements.append('COMMIT;')
    db.query('\n'.join(statements))
    return apply_import(db, imported, verify=True)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--env-file')
    parser.add_argument('--project-name')
    parser.add_argument('--project-directory', default=str(ROOT))
    parser.add_argument('--compose-file', action='append')
    sub = parser.add_subparsers(dest='command', required=True)
    p = sub.add_parser('snapshot'); p.add_argument('--source', required=True); p.add_argument('--groups', required=True); p.add_argument('--output', required=True); p.add_argument('--writers-stopped', action='store_true')
    for name in ('schema', 'import'):
        p = sub.add_parser(name)
        modes = p.add_mutually_exclusive_group(required=True)
        for mode in ('dry-run', 'apply', 'verify'): modes.add_argument('--' + mode, action='store_true')
        p.add_argument('--writers-stopped', action='store_true')
        if name == 'import': p.add_argument('--snapshot', required=True); p.add_argument('--replace-imported', action='store_true')
    args = parser.parse_args(argv)
    if args.command == 'snapshot': report = seal_snapshot(args.source, args.output, args.groups, args.writers_stopped)
    elif args.command == 'schema':
        report = {'schemaVersion': 2, 'tables': sorted(REQUIRED_TABLES), 'additiveBanColumns': ['owner', 'staff']}
        if args.apply:
            if not args.writers_stopped: raise MigrationError('Apply requires explicit --writers-stopped attestation')
            db = Database(args); report = apply_schema(db)
        elif args.verify: report = verify_schema(Database(args))
    else:
        imported = build_import(args.snapshot)
        report = {'snapshotDigest': imported['snapshotDigest'], 'documents': len(imported['documents']), 'discipline': len(imported['discipline']), 'privateDestinationsRequireConfiguration': imported['privateDestinationsRequireConfiguration']}
        if args.apply:
            if not args.writers_stopped: raise MigrationError('Apply requires explicit --writers-stopped attestation')
            report = apply_import(Database(args), imported, args.replace_imported)
        elif args.verify: report = apply_import(Database(args), imported, verify=True)
    print(json.dumps(report, ensure_ascii=False, sort_keys=True))
    return report


if __name__ == '__main__':
    try: main()
    except (MigrationError, OSError, ValueError, subprocess.SubprocessError) as error:
        message = str(error) if isinstance(error, MigrationError) else 'Migration failed; input and database values were suppressed'
        print(message, file=sys.stderr); sys.exit(1)
